import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, terminals, spaces, run, theme, setAgentOrder, openOverlay, layout } from "herdr";

function spaceTrees(agentList, terminalList) {
  const listed = new Map(agentList.map((agent) => [agent.address, agent]));
  const all = new Map(terminalList.map((terminal) => [terminal.address, terminal]));
  const children = new Map();

  for (const terminal of terminalList) {
    if (terminal.state !== "live" || !terminal.parent) continue;

    const siblings = children.get(terminal.parent) ?? [];
    siblings.push(terminal);
    children.set(terminal.parent, siblings);
  }

  const branch = (address, seen = new Set()) => {
    const path = new Set([...seen, address]);

    return {
      address,
      agent: listed.get(address),
      terminal: all.get(address),
      children: (children.get(address) ?? [])
        .filter((child) => !path.has(child.address))
        .map((child) => branch(child.address, path)),
    };
  };
  const bySpace = new Map();

  for (const agent of agentList) {
    const seen = new Set([agent.address]);
    let parent = all.get(agent.address)?.parent;
    let nested = false;

    while (parent && !seen.has(parent)) {
      if (listed.get(parent)?.space === agent.space) {
        nested = true;
        break;
      }

      seen.add(parent);
      parent = all.get(parent)?.parent;
    }

    if (nested) continue;

    const roots = bySpace.get(agent.space) ?? [];
    roots.push(branch(agent.address));
    bySpace.set(agent.space, roots);
  }

  return bySpace;
}

function loadFolded(key) {
  return new Set(JSON.parse(localStorage.getItem(key) ?? "[]"));
}

function toggleFold(folded, key, id, cx) {
  cx.stop_propagation();
  folded.has(id) ? folded.delete(id) : folded.add(id);
  localStorage.setItem(key, JSON.stringify([...folded]));
  cx.notify();
}

export default class SpaceTree extends View {
  init() {
    this.foldedAgents = loadFolded("tree.folded");
    this.foldedSpaces = loadFolded("spaces.folded");
  }

  agentRows(nodes, t, lines = []) {
    return nodes.flatMap((node, index) => {
      const last = index === nodes.length - 1;
      const row = this.agentRow(node, t, [...lines, last ? "└" : "├"]);

      return this.foldedAgents.has(node.address)
        ? [row]
        : [row, ...this.agentRows(node.children, t, [...lines, last ? "" : "│"])];
    });
  }

  agentRow(node, t, lines) {
    const { address, agent, terminal, children } = node;
    const program = agent?.program ?? terminal?.program;
    const rawStatus = agent?.status ?? terminal?.status;
    const status = rawStatus === "error" ? "blocked" : rawStatus;
    const label = agent
      ? (agent.tab_name && !/^\d+$/.test(agent.tab_name) ? agent.tab_name : agent.title || program?.name || address)
      : terminal?.name || terminal?.template || program?.name || address;
    const open = !this.foldedAgents.has(address);
    const color = t[status] ?? t.dim;

    return h_flex().id(`tree-agent-${address}`).h(27).flex_none().pl(18).pr(8).gap(5)
      .items_center().rounded(6).cursor_pointer()
      .when(Boolean(agent?.focused), (el) => el.bg(t.raised))
      .hover((el) => el.bg(t.hover))
      .on_click(() => agent?.pane
        ? run("pane.focus", { pane: agent.pane })
        : run("terminal.peek", { terminal: address }))
      .children(lines.map((line) => div().w(11).flex_none().text_size(12).text_color(t.dim).child(line)))
      .child(div().id(`tree-fold-${address}`).w(14).h(22).flex_none().flex().items_center().justify_center()
        .when(children.length > 0, (el) => el
          .on_click((_event, cx) => toggleFold(this.foldedAgents, "tree.folded", address, cx))
          .child(svg(`mods/workspace-chrome/chevron-${open ? "down" : "right"}.svg`).size(10))))
      .when(Boolean(program?.icon), (el) => el.child(program.tint
        ? svg(program.icon).size(13).flex_none().text_color(t.muted)
        : image(program.icon).w(13).h(13).flex_none()))
      .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.foreground).child(label))
      .when(!open && children.length > 0, (el) => el.child(div().text_size(10).text_color(t.dim).child(String(children.length))))
      .child(status === "working"
        ? svg("mods/workspace-chrome/spinner.svg").size(11).text_color(color).spin(900)
        : div().size(6).flex_none().rounded(3).bg(color))
      .tooltip(`${label} · ${status ?? "unknown"}`);
  }

  spaceRow(space, t, collapsed) {
    const open = !this.foldedSpaces.has(space.id);

    return h_flex().id(`tree-space-${space.id}`).h(30).flex_none().px(8).gap(7)
      .items_center().rounded(7).cursor_pointer()
      .when(space.active, (el) => el.bg(t.selected))
      .hover((el) => el.bg(t.hover))
      .on_click(() => run("space.select", { id: space.id }))
      .on_mouse_down("right", () => openOverlay({
        mod: "space-menu", kind: "popup", width: 200, height: 260,
        props: { tab: "space", target: { id: space.id } },
      }))
      .when(!collapsed, (el) => el.child(div().id(`tree-space-fold-${space.id}`)
        .w(12).h(22).flex_none().flex().items_center()
        .on_click((_event, cx) => toggleFold(this.foldedSpaces, "spaces.folded", space.id, cx))
        .child(svg(`mods/workspace-chrome/chevron-${open ? "down" : "right"}.svg`).size(11).text_color(t.dim))))
      .child(div().size(18).flex_none().rounded(5).bg(t.accent).text_color(t.accent_foreground)
        .flex().items_center().justify_center().text_size(10).font_semibold()
        .child([...space.name][0]?.toUpperCase() ?? "?"))
      .when(!collapsed, (el) => el.child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(space.name))
        .when(space.machine != null, (el) => el.child(div().text_size(10).text_color(t.dim).child(space.machine))))
      .when(Boolean(space.status), (el) => el.child(div().size(6).flex_none().rounded(3).bg(t[space.status] ?? t.dim)))
      .tooltip(space.machine ? `${space.name} · ${space.machine}` : space.name);
  }

  render() {
    const t = theme();
    const list = spaces();
    const trees = spaceTrees(agents(), terminals());
    const order = (nodes) => nodes.flatMap((node) => [node.address, ...order(node.children)]);
    setAgentOrder(list.flatMap((space) => order(trees.get(space.id) ?? [])));

    const sidebar = layout()?.children?.find((node) => node.id === "sidebar");
    const collapsed = (sidebar?.size?.px ?? Infinity) < 160;

    return v_flex().size_full().min_h(0).bg(t.chrome).text_size(13)
      .child(h_flex().h(31).px(12).items_center().justify_between().text_size(11).text_color(t.dim)
        .when(!collapsed, (el) => el.child("Spaces"))
        .child(div().id("tree-space-new").size(24).rounded(5).flex().items_center().justify_center()
          .cursor_pointer().hover((el) => el.bg(t.hover))
          .on_click(() => run("space.new"))
          .child(svg("mods/workspace-chrome/plus.svg").size(13))))
      .child(v_flex().flex_1().min_h(0).px(8).pb(12).overflow_y_scrollbar().mode("always")
        .children(list.map((space) => v_flex().flex_none()
          .child(this.spaceRow(space, t, collapsed))
          .when(!collapsed && !this.foldedSpaces.has(space.id), (el) =>
            el.children(this.agentRows(trees.get(space.id) ?? [], t))))));
  }
}
