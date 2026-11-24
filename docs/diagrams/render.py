"""Render the checked-in logical graphs with TerraVision 0.56.4."""

import argparse
import base64
import html
import json
import re
import subprocess
from pathlib import Path

from modules import annotations, drawing, helpers, html_renderer
from modules.config import cloud_config_azure
from resource_classes.azure import _Azure
from resource_classes.azure.groups import ResourceGroupCluster, SharedServicesGroup


class GatewayIcon(_Azure):
    _icon_dir = str(Path(__file__).resolve().parent)
    _icon = "ai-gateway.png"


# Agent and project icons are from Microsoft's Azure architecture icon pack:
# https://learn.microsoft.com/en-us/azure/architecture/icons/
class FoundryAgentIcon(_Azure):
    _icon_dir = str(Path(__file__).resolve().parent)
    _icon = "foundry-agent.png"


class FoundryProjectIcon(_Azure):
    _icon_dir = str(Path(__file__).resolve().parent)
    _icon = "foundry-project.png"


class FoundryModelsIcon(_Azure):
    _icon_dir = str(Path(__file__).resolve().parent)
    _icon = "foundry-models.png"


class SpaciousResourceGroup(ResourceGroupCluster):
    _margin_scale = 1.5


class CompactOverviewResourceGroup(SpaciousResourceGroup):
    _margin_scale = 1.125


class OverviewLogicalGroup(SharedServicesGroup):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.dot.graph_attr["margin"] = "67.5"
        icons = {
            "Foundry Account": "foundry-account.png",
            "Foundry Project": "foundry-project.png",
        }
        if self.label in icons:
            self.label_text = self.label
            self.label_icon = str(Path(__file__).resolve().parent / icons[self.label])
            self.label_icon_width = self.label_icon_height = 94
            self.label_position = "bottom-left"
            self.dot.graph_attr["label"] = ""
        if self.label == "Foundry Project":
            self.dot.node(
                "_project_pull_anchor", label="", shape="point",
                width="0.01", height="0.01", style="invis",
            )
        if self.label == "infra/backend | separate state, NOT another RG":
            self.dot.graph_attr["label"] = ""


TELEMETRY_COLOR = "#7134a0"
IMAGE_PULL_COLOR = "#b34e00"
REQUEST_COLOR = "#16713c"
ICON_SCALE = 0.75
OVERVIEW_SCALE = 0.75


def overview_azure_node(original):
    def init(node, label="", **kwargs):
        kwargs.update(width="2.85", height="3.9", fontsize="21", margin="0.45,0.75")
        original(node, label, **kwargs)

    return init


def overview_edge(original):
    telemetry = {
        "azurerm_application_insights.agent_telemetry",
        "azurerm_application_insights.gateway_telemetry",
        "azurerm_log_analytics_workspace.logs",
        "azurerm_monitor_workspace.metrics",
    }

    def make_edge(data, source, target, **kwargs):
        kwargs["penwidth"] = "4"
        request_steps = data["annotations"]["flows"]["request"]["steps"]
        if any(step["resource"] == f"{source} -> {target}" for step in request_steps):
            kwargs["color"] = REQUEST_COLOR
        elif target in telemetry:
            kwargs["color"] = TELEMETRY_COLOR
        elif target == "azurerm_container_registry.images":
            kwargs["color"] = IMAGE_PULL_COLOR
        return original(data, source, target, **kwargs)

    return make_edge


def route_overview_edges(original, data):
    def route(path, outfile):
        postdot = original(path, outfile)
        adjusted = postdot.with_suffix(".adjusted.dot")
        routed = postdot.with_suffix(".ortho.dot")
        connection = data["annotations"]["boundary_connections"][0]
        project = next(
            name for name, resource in data["cluster_id_map"].items()
            if resource == connection["from"]
        )
        gateway = next(
            name for name, resource in data["cluster_id_map"].items()
            if resource == "azurerm_resource_group.gateway"
        )
        logging = next(
            name for name, resource in data["cluster_id_map"].items()
            if resource == "azurerm_resource_group.logging"
        )
        gateway_nodes = [
            data["meta_data"][resource]["node"].nodeid
            for resource in (
                "azurerm_ski_ai_gateway.gateway",
                "azurerm_application_insights.gateway_telemetry",
            )
        ]
        logging_nodes = [
            data["meta_data"][resource]["node"].nodeid
            for resource in (
                "azurerm_log_analytics_workspace.logs",
                "azurerm_monitor_workspace.metrics",
            )
        ]
        project_box = re.search(
            rf'subgraph "{re.escape(project)}"\s*\{{\s*graph \[.*?\bbb="([^"]+)"',
            postdot.read_text(encoding="utf-8"),
            re.DOTALL,
        )
        if not project_box:
            raise ValueError("Project boundary missing from laid-out graph")
        _, bottom, right, _ = map(float, project_box.group(1).split(","))
        try:
            # The cloud logo overlaps the logging label after TerraVision moves
            # the boxes, which otherwise makes neato abandon orthogonal routing.
            subprocess.run(
                [
                    "gvpr", "-c",
                    'N[hasAttr($, "_clustertype") && $._clustertype == "AZUREGroup"]'
                    ' { double x; double y; sscanf($.pos, "%lf,%lf", &x, &y);'
                    ' $.pos=sprintf("%.2f,%.2f!", x, y-120); }'
                    ' N[$.name=="_project_pull_anchor"]'
                    f' {{ $.pos="{right - 90:.1f},{bottom:.1f}!"; }}'
                    f' N[$.name=="{gateway_nodes[0]}" || $.name=="{gateway_nodes[1]}"'
                    f' || (hasAttr($, "_clusterid") && $._clusterid=="{gateway}")]'
                    ' { double gx; double gy; sscanf($.pos, "%lf,%lf", &gx, &gy);'
                    ' $.pos=sprintf("%.2f,%.2f!", gx, gy+240); }'
                    f' N[$.name=="{logging_nodes[0]}" || $.name=="{logging_nodes[1]}"'
                    f' || (hasAttr($, "_clusterid") && $._clusterid=="{logging}")]'
                    ' { double lx; double ly; sscanf($.pos, "%lf,%lf", &lx, &ly);'
                    ' $.pos=sprintf("%.2f,%.2f!", lx, ly-160); }',
                    str(postdot), "-o", str(adjusted),
                ],
                check=True,
            )
            dot = adjusted.read_text(encoding="utf-8")
            for cluster, offset in ((gateway, 240), (logging, -160)):
                pattern = rf'(subgraph "{re.escape(cluster)}"\s*\{{\s*graph \[.*?\bbb=")([^"]+)(")'

                def move_box(match):
                    x0, y0, x1, y1 = map(float, match.group(2).split(","))
                    return f"{match.group(1)}{x0},{y0 + offset},{x1},{y1 + offset}{match.group(3)}"

                dot, count = re.subn(pattern, move_box, dot, count=1, flags=re.DOTALL)
                if count != 1:
                    raise ValueError(f"Boundary missing from laid-out graph: {cluster}")
            adjusted.write_text(dot, encoding="utf-8")
            result = subprocess.run(
                [
                    "neato", "-n", "-Goverlap=true", "-Gsplines=ortho", "-Tdot",
                    str(adjusted), "-o", str(routed),
                ],
                check=True, capture_output=True, text=True,
            )
            if result.stderr:
                raise ValueError(f"Orthogonal routing warning: {result.stderr.strip()}")
            routed.replace(postdot)
        finally:
            adjusted.unlink(missing_ok=True)
            routed.unlink(missing_ok=True)
        return postdot

    return route


def add_overview_legend(path, data):
    text = path.read_text(encoding="utf-8")
    marker = '    <div id="controls">'
    if text.count(marker) != 1:
        raise ValueError("Expected one diagram controls element")
    node_ids = {resource: node for node, resource in data["node_id_map"].items()}
    clusters = {resource: cluster for cluster, resource in data["cluster_id_map"].items()}
    notes = data["annotations"]
    steps = notes["flows"]["request"]["steps"]
    details = notes["step_details"]
    if len(steps) != len(details):
        raise ValueError("Each request step must have a detail")
    overview = {
        "groups": {
            clusters[resource]: detail for resource, detail in notes["group_details"].items()
        },
        "steps": {
            "->".join(node_ids[resource] for resource in step["resource"].split(" -> ")): {
                "title": f"Step {index}",
                "detail": detail,
            }
            for index, (step, detail) in enumerate(zip(steps, details), start=1)
        },
    }
    legend = f'''    <style>
        #flow-legend {{ position:fixed; bottom:12px; left:12px; z-index:50; background:white;
            border:1px solid #ccc; border-radius:6px; padding:8px 12px; font:bold 14px sans-serif; }}
        #flow-legend button {{ display:block; border:0; padding:3px; background:transparent;
            color:#222; font:inherit; text-align:left; cursor:pointer; }}
        #flow-legend button:focus-visible {{ outline:2px solid #222; outline-offset:2px; }}
        #flow-legend button[aria-pressed="true"] {{ background:#e9eef3; }}
        .edge.flow-dim {{ opacity:0.16; }}
        .edge.flow-highlight > path:not(.flow-streak):not(.flow-trail):not(.edge-bold-underlay) {{ stroke-width:7; }}
        .edge:focus-visible {{ outline:2px solid #333; }}
        .cluster.rg-highlight > polygon {{ stroke:#0873a5; stroke-width:5;
            stroke-dasharray:none; fill:#0873a5; fill-opacity:0.06; }}
        .cluster[data-overview]:focus-visible {{ outline:2px solid #0873a5; }}
        #diagram-detail {{ position:fixed; top:68px; right:12px; z-index:60;
            max-width:340px; padding:12px; border:1px solid #aaa; border-radius:6px;
            background:white; color:#222; box-shadow:0 2px 8px #0003;
            font:14px/1.45 sans-serif; pointer-events:none; }}
        #diagram-detail strong {{ display:block; margin-bottom:5px; }}
        .flow-streak {{ display:none; fill:none; stroke:white; stroke-width:2.5;
            stroke-dasharray:20 50; pointer-events:none; }}
        .edge.flow-highlight > .flow-streak {{ display:inline; animation:flow-direction 1s linear infinite; }}
        @keyframes flow-direction {{ to {{ stroke-dashoffset:-70; }} }}
        @media (prefers-reduced-motion:reduce) {{
            .edge.flow-highlight > .flow-streak {{ animation:none; display:none; }}
        }}
    </style>
    <div id="flow-legend" role="group" aria-label="Highlight connection types">
        <button type="button" data-flow="request" aria-pressed="false"><span style="display:inline-block;width:25px;border-top:4px solid {REQUEST_COLOR};vertical-align:middle"></span> User request flow</button>
        <button type="button" data-flow="telemetry" aria-pressed="false"><span style="display:inline-block;width:25px;border-top:4px solid {TELEMETRY_COLOR};vertical-align:middle"></span> Telemetry / logging</button>
        <button type="button" data-flow="images" aria-pressed="false"><span style="display:inline-block;width:25px;border-top:4px solid {IMAGE_PULL_COLOR};vertical-align:middle"></span> Container image pulls</button>
    </div>
    <div id="diagram-detail" role="tooltip" hidden><strong></strong><span></span></div>

'''
    script = '''
    <script>
    (function () {
        const overview = __OVERVIEW_DATA__;
        const colors = {
            "#16713c": "request", "#7134a0": "telemetry", "#b34e00": "images"
        };
        const labels = {
            request: "User request flow", telemetry: "Telemetry / logging",
            images: "Container image pulls"
        };
        const edges = Array.from(document.querySelectorAll("g.edge")).filter(edge => {
            const line = edge.querySelector("path");
            const kind = line && colors[(line.getAttribute("stroke") || "").toLowerCase()];
            if (!kind) return false;
            edge.dataset.flow = kind;
            edge.setAttribute("tabindex", "0");
            const description = Array.from(edge.querySelectorAll("text"))
                .map(item => item.textContent.trim()).join(" ").trim();
            edge.setAttribute("aria-label", description || labels[kind] + " connection");
            const streak = line.cloneNode(false);
            streak.removeAttribute("id");
            streak.setAttribute("class", "flow-streak");
            edge.appendChild(streak);
            return true;
        });
        const buttons = Array.from(document.querySelectorAll("#flow-legend button"));
        let pinned = null;
        function highlight(kind) {
            edges.forEach(edge => {
                edge.classList.toggle("flow-highlight", !!kind && edge.dataset.flow === kind);
                edge.classList.toggle("flow-dim", !!kind && edge.dataset.flow !== kind);
            });
        }
        function bind(element) {
            element.addEventListener("pointerenter", () => highlight(element.dataset.flow));
            element.addEventListener("pointerleave", () => {
                highlight(element.matches(":focus-visible") ? element.dataset.flow : pinned);
            });
            element.addEventListener("focus", () => highlight(element.dataset.flow));
            element.addEventListener("blur", () => highlight(pinned));
        }
        edges.forEach(bind);
        buttons.forEach(button => {
            bind(button);
            button.addEventListener("click", () => {
                pinned = pinned === button.dataset.flow ? null : button.dataset.flow;
                buttons.forEach(item => item.setAttribute("aria-pressed", String(item.dataset.flow === pinned)));
                highlight(pinned);
            });
        });

        const tooltip = document.getElementById("diagram-detail");
        const groups = Array.from(document.querySelectorAll("g.cluster")).filter(group => {
            const title = group.querySelector("title");
            const info = title && overview.groups[title.textContent.trim()];
            if (!info) return false;
            group.dataset.overview = title.textContent.trim();
            group.setAttribute("tabindex", "0");
            group.setAttribute("role", "img");
            group.setAttribute("aria-label", info.title);
            group.setAttribute("aria-describedby", "diagram-detail");
            return true;
        });
        function showInfo(info) {
            tooltip.querySelector("strong").textContent = info.title;
            tooltip.querySelector("span").textContent = info.detail;
            tooltip.hidden = false;
        }
        function highlightGroup(group) {
            groups.forEach(item => item.classList.toggle("rg-highlight", item === group));
        }
        let focusedDetail = false;
        groups.forEach(group => {
            group.addEventListener("focus", () => {
                focusedDetail = true;
                highlightGroup(group);
                showInfo(overview.groups[group.dataset.overview]);
            });
            group.addEventListener("blur", () => {
                focusedDetail = false;
                highlightGroup(null);
                tooltip.hidden = true;
            });
        });
        edges.forEach(edge => {
            const title = edge.querySelector("title");
            const info = title && overview.steps[title.textContent.trim()];
            const badge = info && edge.querySelector("image");
            if (!badge) return;
            badge.dataset.step = title.textContent.trim();
            badge.setAttribute("tabindex", "0");
            badge.setAttribute("role", "img");
            badge.setAttribute("aria-label", info.title);
            badge.setAttribute("aria-describedby", "diagram-detail");
            badge.style.cursor = "help";
            badge.addEventListener("focus", () => {
                focusedDetail = true;
                showInfo(info);
            });
            badge.addEventListener("blur", () => {
                focusedDetail = false;
                tooltip.hidden = true;
            });
        });
        const svg = document.querySelector("#graph svg");
        svg.addEventListener("pointermove", event => {
            if (focusedDetail) return;
            const group = groups.find(item => {
                const box = item.querySelector("polygon").getBoundingClientRect();
                return event.clientX >= box.left && event.clientX <= box.right &&
                    event.clientY >= box.top && event.clientY <= box.bottom;
            });
            highlightGroup(group || null);
            const badge = event.target.closest("image[data-step]");
            const info = badge ? overview.steps[badge.dataset.step] :
                group && overview.groups[group.dataset.overview];
            if (info) showInfo(info);
            else tooltip.hidden = true;
        });
        svg.addEventListener("pointerleave", () => {
            if (focusedDetail) return;
            highlightGroup(null);
            tooltip.hidden = true;
        });
        document.addEventListener("keydown", event => {
            if (event.key === "Escape" && !tooltip.hidden) {
                if (document.activeElement) document.activeElement.blur();
                focusedDetail = false;
                highlightGroup(null);
                tooltip.hidden = true;
            }
        });
    })();
    </script>
'''
    if text.count("</body>") != 1:
        raise ValueError("Expected one diagram body")
    payload = json.dumps(overview, ensure_ascii=True).replace("<", "\\u003c")
    script = script.replace("__OVERVIEW_DATA__", payload)
    text = text.replace(marker, legend + marker).replace("</body>", script + "</body>")
    path.write_text(text, encoding="utf-8")


def align_overview_groups(data, original):
    def pre_render(canvas):
        registry = data["meta_data"]["azurerm_container_registry.images"]["node"].nodeid
        logs = data["meta_data"]["azurerm_log_analytics_workspace.logs"]["node"].nodeid
        edge = f'"{registry}" -> "{logs}" ['
        matches = sum(edge in line for line in canvas.dot.body)
        if matches != 1:
            raise ValueError("Expected one registry-to-logging edge for overview layout")
        canvas.dot.body = [
            line.replace(edge, edge + "constraint=false ")
            for line in canvas.dot.body
        ]
        canvas.dot.graph_attr["newrank"] = "true"
        canvas.dot.graph_attr["splines"] = "ortho"
        canvas.dot.graph_attr["fontname"] = "Sans-Serif Bold"
        canvas.dot.node_attr["fontname"] = "Sans-Serif Bold"
        canvas.dot.edge_attr["fontname"] = "Sans-Serif Bold"
        connection = data["annotations"]["boundary_connections"][0]
        if connection["from"] not in data["cluster_id_map"].values():
            raise ValueError("Project boundary missing from overview")
        target = data["meta_data"][connection["to"]]["node"].nodeid
        canvas.dot.edge(
            "_project_pull_anchor", target, color=IMAGE_PULL_COLOR,
            penwidth="4", dir="forward",
            xlabel=(
                '<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0"><TR>'
                f'<TD BGCOLOR="white"><FONT POINT-SIZE="28" COLOR="{IMAGE_PULL_COLOR}">'
                f'{html.escape(connection["label"])}</FONT></TD></TR></TABLE>>'
            ),
            fontsize="28", fontcolor=IMAGE_PULL_COLOR, constraint="false",
        )
        canvas.dot.body = [
            line.replace('fontname="Sans-Serif"', 'fontname="Sans-Serif Bold"')
            for line in canvas.dot.body
        ]
        with canvas.dot.subgraph() as row:
            row.attr(rank="same")
            row.node(registry)
            row.node(logs)
        return original(canvas)

    return pre_render


def align_overview_cards(path, data):
    text = path.read_text(encoding="utf-8")
    resources = set(data["node_id_map"])
    aligned = set()
    padding = 24 * OVERVIEW_SCALE

    def align(match):
        card = match.group()
        title = re.search(r"<title>(.*?)</title>", card)
        if not title or html.unescape(title.group(1)) not in resources:
            return card
        path_match = re.search(r'<path\b[^>]* d="([^"]+)"', card)
        image_match = re.search(r"<image\b[^>]*/>", card)
        labels = list(re.finditer(r'<text\b[^>]* y="([^"]+)"[^>]*>', card))
        if not path_match or not image_match or not labels:
            raise ValueError(f"Cannot align card: {title.group(1)}")
        points = [
            tuple(map(float, pair))
            for pair in re.findall(r"(-?[\d.]+),(-?[\d.]+)", path_match.group(1))
        ]
        left, right = min(p[0] for p in points), max(p[0] for p in points)
        top, bottom = min(p[1] for p in points), max(p[1] for p in points)
        label_bottom = max(float(label.group(1)) for label in labels)
        shift = bottom - padding - label_bottom

        def move_label(label):
            tag = label.group()
            return re.sub(
                r'\by="[^"]+"',
                f'y="{float(label.group(1)) + shift:.2f}"',
                tag,
                count=1,
            )

        card = re.sub(r'<text\b[^>]* y="([^"]+)"[^>]*>', move_label, card)
        first_label = min(float(label.group(1)) for label in labels) + shift
        font_size = float(re.search(r'font-size="([^"]+)"', labels[0].group()).group(1))
        image_bottom = first_label - font_size - padding
        size = min(right - left - 2 * padding, image_bottom - top - padding)
        if size <= 0:
            raise ValueError(f"No room for icon: {title.group(1)}")
        size *= ICON_SCALE
        x = (left + right - size) / 2
        y = (top + padding + image_bottom - size) / 2

        def move_image(image):
            tag = image.group()
            for attr, value in (("x", x), ("y", y), ("width", size), ("height", size)):
                tag, count = re.subn(
                    rf'\b{attr}="[^"]+"', f'{attr}="{value:.2f}"', tag, count=1
                )
                if count != 1:
                    raise ValueError(f"Missing image {attr}: {title.group(1)}")
            if "preserveAspectRatio=" in tag:
                return re.sub(
                    r'preserveAspectRatio="[^"]+"',
                    'preserveAspectRatio="xMidYMid meet"',
                    tag,
                    count=1,
                )
            return tag.replace("/>", ' preserveAspectRatio="xMidYMid meet"/>')

        card = re.sub(r"<image\b[^>]*/>", move_image, card, count=1)
        aligned.add(html.unescape(title.group(1)))
        return card

    text = re.sub(r'<g id="node\d+" class="node">.*?</g>', align, text, flags=re.DOTALL)
    if aligned != resources:
        raise ValueError(f"Missing overview cards: {sorted(resources - aligned)}")

    def scale_boundary_icon(match):
        node = match.group()
        title = re.search(r"<title>(.*?)</title>", node)
        if not title or not title.group(1).startswith("_label_cluster_"):
            return node

        def scale_image(image):
            tag = image.group()
            values = {}
            for attr in ("x", "y", "width", "height"):
                value = re.search(rf'\b{attr}="(-?[\d.]+)(px)?"', tag)
                if not value:
                    raise ValueError(f"Missing image {attr}: {title.group(1)}")
                values[attr] = (float(value.group(1)), value.group(2) or "")
            for axis, dimension in (("x", "width"), ("y", "height")):
                position, unit = values[axis]
                size, _ = values[dimension]
                scale = ICON_SCALE * OVERVIEW_SCALE
                values[axis] = (position + size * (1 - scale) / 2, unit)
                values[dimension] = (size * scale, values[dimension][1])
            for attr, (value, unit) in values.items():
                tag = re.sub(rf'\b{attr}="[^"]+"', f'{attr}="{value:.2f}{unit}"', tag, count=1)
            return tag

        return re.sub(r"<image\b[^>]*/>", scale_image, node, count=1)

    text = re.sub(
        r'<g id="node\d+" class="node">.*?</g>',
        scale_boundary_icon,
        text,
        flags=re.DOTALL,
    )

    group_bounds = {}
    for cluster in re.findall(r'<g id="clust\d+" class="cluster">.*?</g>', text, re.DOTALL):
        title = re.search(r"<title>(.*?)</title>", cluster)
        polygon = re.search(r'<polygon\b[^>]* points="([^"]+)"', cluster)
        if title and polygon and title.group(1).startswith("cluster_CompactOverviewResourceGroup."):
            points = [tuple(map(float, point.split(","))) for point in polygon.group(1).split()]
            group_bounds[title.group(1)] = (
                min(x for x, _ in points),
                max(y for _, y in points),
            )

    def move_resource_group_label(match):
        node = match.group()
        title = re.search(r"<title>_label_(cluster_CompactOverviewResourceGroup\.\d+)</title>", node)
        if not title:
            return node
        image = re.search(r"<image\b[^>]*/>", node)
        if not image or title.group(1) not in group_bounds:
            raise ValueError(f"Cannot position resource group label: {title.group(1)}")
        attrs = {
            attr: float(re.search(rf'\b{attr}="(-?[\d.]+)', image.group()).group(1))
            for attr in ("x", "y", "height")
        }
        left, bottom = group_bounds[title.group(1)]
        dx = left + 8 - attrs["x"]
        dy = bottom - 8 - attrs["y"] - attrs["height"]
        return node.replace('class="node">', f'class="node" transform="translate({dx:.2f} {dy:.2f})">', 1)

    text = re.sub(
        r'<g id="node\d+" class="node">.*?</g>',
        move_resource_group_label,
        text,
        flags=re.DOTALL,
    )

    def bold_text(match):
        tag = match.group().replace('font-family="Sans-Serif Bold"', 'font-family="sans-serif"')
        if "font-weight=" not in tag:
            tag = tag[:-1] + ' font-weight="bold">'
        return tag

    text = re.sub(r"<text\b[^>]*>", bold_text, text)
    path.write_text(text, encoding="utf-8")


def embed_images(path, data):
    text = path.read_text(encoding="utf-8")
    badges = "".join(
        value
        for key in ("flow_badges", "flow_edge_badges")
        for value in data.get(key, {}).values()
    )
    allowed_badges = set(re.findall(r'SRC="([^"]+)"', badges))
    references = set(re.findall(r'<image\b[^>]*href="([^"]+)"', text))
    for reference in references:
        if reference.startswith("data:"):
            continue
        diagram_icons = {
            str(Path(__file__).resolve().parent / icon)
            for icon in (
                "ai-gateway.png",
                "foundry-account.png",
                "foundry-agent.png",
                "foundry-project.png",
                "foundry-models.png",
            )
        }
        if (
            not helpers.is_bundled_image(reference)
            and reference not in allowed_badges
            and reference not in diagram_icons
        ):
            raise ValueError(f"Unapproved image reference: {reference}")
        image = Path(reference)
        mime = "image/svg+xml" if image.suffix == ".svg" else "image/png"
        encoded = base64.b64encode(image.read_bytes()).decode("ascii")
        text = text.replace(reference, f"data:{mime};base64,{encoded}")
    path.write_text(text, encoding="utf-8")


def add_html_notices(path, directory):
    text = path.read_text(encoding="utf-8")
    notices = (directory / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
    license_text = (directory / "LICENSE-terravision.txt").read_text(encoding="utf-8")
    if text.count("</head>") != 1 or "</script" in (notices + license_text).lower():
        raise ValueError("Cannot embed third-party notices")
    licenses = f'<script type="text/plain" id="third-party-licenses">\n{notices}\n{license_text}\n</script>\n'
    path.write_text(text.replace("</head>", licenses + "</head>"), encoding="utf-8")


def position_request_labels(path, data):
    text = path.read_text(encoding="utf-8")
    node_ids = {resource: node for node, resource in data["node_id_map"].items()}
    targets = {
        (node_ids["azurerm_container_app.website"], node_ids["azurerm_ski_foundry_agent.agent"]): "above",
        (node_ids["azurerm_ski_foundry_agent.agent"], node_ids["azurerm_ski_ai_gateway.gateway"]): "above",
        (node_ids["azurerm_ski_ai_gateway.gateway"], node_ids["azurerm_ai_foundry.toolbox"]): "below-left",
        (node_ids["azurerm_ski_ai_gateway.gateway"], node_ids["azurerm_ski_foundry_models.models"]): "right",
    }
    positioned = set()

    def position(match):
        edge = match.group()
        title = re.search(r"<title>(.*?)</title>", edge)
        endpoints = tuple(html.unescape(title.group(1)).split("->")) if title else ()
        if endpoints not in targets:
            return edge
        route = re.search(r'<path\b[^>]* d="([^"]+)"', edge)
        image = re.search(r"<image\b[^>]*/>", edge)
        background = re.search(r'<polygon\b[^>]* fill="white"[^>]* points="([^"]+)"[^>]*/>', edge)
        if not route or not image or not background:
            raise ValueError(f"Cannot position request label: {endpoints}")
        points = [tuple(map(float, pair)) for pair in re.findall(r"(-?[\d.]+),(-?[\d.]+)", route.group(1))]
        bg_points = [tuple(map(float, point.split(","))) for point in background.group(1).split()]
        image_x = float(re.search(r'\bx="(-?[\d.]+)"', image.group()).group(1))
        left = min(image_x, *(x for x, _ in bg_points))
        right = max(x for x, _ in bg_points)
        top, bottom = min(y for _, y in bg_points), max(y for _, y in bg_points)
        if targets[endpoints] == "right":
            vertical = {}
            for x, y in points:
                vertical.setdefault(x, []).append(y)
            x, ys = max(vertical.items(), key=lambda item: max(item[1]) - min(item[1]))
            if max(ys) == min(ys):
                raise ValueError(f"No vertical segment for request label: {endpoints}")
            dx, dy = x + 8 - left, 0
        else:
            horizontal = {}
            for x, y in points:
                horizontal.setdefault(y, []).append(x)
            y, xs = max(horizontal.items(), key=lambda item: max(item[1]) - min(item[1]))
            if max(xs) == min(xs):
                raise ValueError(f"No horizontal segment for request label: {endpoints}")
            dx = (
                min(xs) + 10 - left if targets[endpoints] == "below-left"
                else (min(xs) + max(xs) - (right - left)) / 2 - left
            )
            dy = (
                y + 8 - top if targets[endpoints] == "below-left"
                else y - 8 - bottom
            )
        transform = f'transform="translate({dx:.2f} {dy:.2f})"'
        edge = edge.replace(image.group(), image.group().replace("<image ", f"<image {transform} ", 1), 1)
        edge = edge.replace(background.group(), background.group().replace("<polygon ", f"<polygon {transform} ", 1), 1)
        edge = re.sub(r"<text\b", f"<text {transform}", edge)
        positioned.add(endpoints)
        return edge

    text = re.sub(r'<g id="edge\d+" class="edge">.*?</g>', position, text, flags=re.DOTALL)
    if positioned != set(targets):
        raise ValueError(f"Missing request labels: {set(targets) - positioned}")
    path.write_text(text, encoding="utf-8")


def spread_logging_connections(path, data):
    text = path.read_text(encoding="utf-8")
    node_ids = {resource: node for node, resource in data["node_id_map"].items()}
    target = node_ids["azurerm_log_analytics_workspace.logs"]
    source = node_ids["azurerm_cdn_frontdoor_profile.edge"]
    frontend = node_ids["azurerm_container_app.website"]

    def card_bounds(node):
        for group in re.findall(r'<g id="node\d+" class="node">.*?</g>', text, re.DOTALL):
            title = re.search(r"<title>(.*?)</title>", group)
            if title and html.unescape(title.group(1)) == node:
                card = re.search(r'<path\b[^>]* d="([^"]+)"', group)
                if card:
                    points = [tuple(map(float, point)) for point in re.findall(r"(-?[\d.]+),(-?[\d.]+)", card.group(1))]
                    return min(x for x, _ in points), max(x for x, _ in points), min(y for _, y in points), max(y for _, y in points)
        raise ValueError(f"Missing overview card: {node}")

    left, _, top, _ = card_bounds(target)
    front_left, front_right, _, front_bottom = card_bounds(frontend)
    lane_x, arrival_y = left - 50, top + 32

    updated_count = 0

    def reroute(match):
        nonlocal updated_count
        edge = match.group()
        title = re.search(r"<title>(.*?)</title>", edge)
        if not title:
            return edge
        endpoints = html.unescape(title.group(1))
        if endpoints not in (f"{source}->{target}", f"{frontend}->{target}"):
            return edge
        route = re.search(r'<path\b[^>]* d="([^"]+)"', edge)
        arrow = re.search(r'<polygon\b[^>]* fill="#7134a0"[^>]* points="([^"]+)"[^>]*/>', edge)
        if not route or not arrow:
            raise ValueError(f"Cannot reroute logging connection: {endpoints}")
        route_points = list(re.finditer(r"(-?[\d.]+),(-?[\d.]+)", route.group(1)))
        if endpoints == f"{frontend}->{target}":
            last_x, last_y = map(float, route_points[-1].groups())
            start_x = (front_left + front_right) / 2
            new_route = (
                f"M{start_x:.2f},{front_bottom:.2f} L{start_x:.2f},{front_bottom + 40:.2f} "
                f"L{last_x:.2f},{front_bottom + 40:.2f} L{last_x:.2f},{last_y:.2f}"
            )
            updated_count += 1
            return edge.replace(route.group(1), new_route, 1)
        old_x = float(route_points[-1].group(1))
        old_y = float(route_points[-1].group(2))
        if len(route_points) < 4 or abs(float(route_points[-2].group(1)) - old_x) > 0.1:
            raise ValueError("Unexpected Front Door logging route")

        def move_point(point):
            x, y = float(point.group(1)), float(point.group(2))
            if abs(x - old_x) < 0.1:
                x = lane_x
                if abs(y - old_y) < 0.1:
                    y = arrival_y
            return f"{x:.2f},{y:.2f}"

        new_route = re.sub(r"(-?[\d.]+),(-?[\d.]+)", move_point, route.group(1))
        new_route += f" L{left - 15:.2f},{arrival_y:.2f}"
        new_arrow = (
            f"{left - 15:.2f},{arrival_y - 5.25:.2f} {left:.2f},{arrival_y:.2f} "
            f"{left - 15:.2f},{arrival_y + 5.25:.2f} {left - 15:.2f},{arrival_y - 5.25:.2f}"
        )
        edge = edge.replace(route.group(1), new_route, 1).replace(arrow.group(1), new_arrow, 1)
        transform = f'transform="translate({lane_x - old_x:.2f} 0)"'
        edge = re.sub(r'<polygon(?=\s[^>]*fill="white")', f"<polygon {transform}", edge)
        edge = re.sub(r"<text\b", f"<text {transform}", edge)
        updated_count += 1
        return edge

    text = re.sub(r'<g id="edge\d+" class="edge">.*?</g>', reroute, text, flags=re.DOTALL)
    if updated_count != 2:
        raise ValueError("Expected Front Door and frontend logging connections")
    path.write_text(text, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("names", nargs="*", help="Diagram names; default: all")
    parser.add_argument("--format", choices=("html", "svg", "png"), default="html")
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    directory = Path(__file__).resolve().parent
    names = args.names or sorted(
        path.stem.removesuffix(".tvg") for path in directory.glob("*.tvg.json")
    )
    unknown = [
        name for name in names if not (directory / f"{name}.tvg.json").is_file()
    ]
    if unknown:
        parser.error(f"Unknown diagrams: {', '.join(unknown)}")
    output = args.output_dir or directory
    output.mkdir(parents=True, exist_ok=True)

    # TerraVision normally suppresses ACR/Log Analytics arrows. These diagrams
    # explicitly document those flows, so retain shared-service connections.
    cloud_config_azure.AZURE_SHARED_SERVICES = []
    drawing._load_provider_resources("azure")
    drawing.azurerm_ski_ai_gateway = GatewayIcon
    drawing.azurerm_ski_foundry_agent = FoundryAgentIcon
    drawing.azurerm_ski_foundry_project = FoundryProjectIcon
    drawing.azurerm_ski_foundry_models = FoundryModelsIcon
    drawing.avl_classes.extend(
        [
            "azurerm_ski_ai_gateway",
            "azurerm_ski_foundry_agent",
            "azurerm_ski_foundry_project",
            "azurerm_ski_foundry_models",
        ]
    )
    default_pre_render = drawing.Canvas.pre_render
    default_edge = drawing._make_edge_with_badge
    default_label_shift = drawing._run_gvpr_label_shift
    default_group = drawing.azurerm_group
    default_azure_init = _Azure.__init__
    for name in names:
        graph = json.loads(
            (directory / f"{name}.tvg.json").read_text(encoding="utf-8")
        )
        notes = json.loads(
            (directory / f"{name}.annotations.json").read_text(encoding="utf-8")
        )
        data = {"graphdict": graph, "meta_data": {}, "annotations": notes}
        drawing.azurerm_resource_group = (
            CompactOverviewResourceGroup if name == "architecture" else SpaciousResourceGroup
        )
        _Azure.__init__ = (
            overview_azure_node(default_azure_init)
            if name == "architecture"
            else default_azure_init
        )
        drawing.azurerm_group = (
            OverviewLogicalGroup if name == "architecture" else default_group
        )
        drawing.Canvas.pre_render = (
            align_overview_groups(data, default_pre_render)
            if name == "architecture"
            else default_pre_render
        )
        drawing._make_edge_with_badge = (
            overview_edge(default_edge) if name == "architecture" else default_edge
        )
        drawing._run_gvpr_label_shift = (
            route_overview_edges(default_label_shift, data)
            if name == "architecture"
            else default_label_shift
        )
        warnings = annotations.apply_attribute_updates(data, notes.get("update"))
        warnings += annotations.apply_edge_labels(data, notes.get("connect"))
        if warnings:
            raise ValueError("\n".join(warnings))
        source = f"docs/diagrams/{name}.tvg.json (logical view; not a Terraform plan)"
        if args.format == "html":
            html_renderer.render_html(
                data, show=False, outfile=str(output / name), source=source
            )
            (output / f"{name}.dot").unlink()
        else:
            drawing.render_diagram(
                data,
                picshow=False,
                outfile=str(output / name),
                format=args.format,
                source=source,
            )
            (output / f"{name}.dot.{args.format}").replace(
                output / f"{name}.{args.format}"
            )
        if args.format in ("html", "svg"):
            embed_images(output / f"{name}.{args.format}", data)
            if name == "architecture":
                align_overview_cards(output / f"{name}.{args.format}", data)
                position_request_labels(output / f"{name}.{args.format}", data)
                spread_logging_connections(output / f"{name}.{args.format}", data)
        if name == "architecture" and args.format == "html":
            add_overview_legend(output / f"{name}.html", data)
        if args.format == "html":
            add_html_notices(output / f"{name}.html", directory)
        leaves = {
            node for node in graph
            if not node.startswith(("azurerm_resource_group.", "azurerm_group."))
        }
        missing = leaves - set(data.get("node_id_map", {}).values())
        if missing:
            raise ValueError(f"{name}: nodes missing from diagram: {sorted(missing)}")
        node_names = data["node_id_map"]
        connections = {
            (node_names[source], node_names[target])
            for source, targets in data["connected_nodes"].items()
            for target in targets
            if source in node_names and target in node_names
        }
        missing_edges = {
            (source, target)
            for source in leaves
            for target in graph[source]
        } - connections
        if missing_edges:
            raise ValueError(
                f"{name}: arrows missing from diagram: {sorted(missing_edges)}"
            )


if __name__ == "__main__":
    main()
