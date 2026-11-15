import { View, div, svg } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { layout, run, theme, updates } from "herdr";

export default class SidebarFooter extends View {
  render() {
    const t = theme();
    const sidebar = layout()?.children?.find((node) => node.id === "sidebar");
    const collapsed = (sidebar?.size?.px ?? Infinity) < 160;
    const ready = div().size(6).rounded_full().bg(t.accent);

    return v_flex().size_full().bg(t.chrome).border_t(1).border_color(t.border).px(collapsed ? 0 : 8).justify_center().text_size(13)
      .when(collapsed, (el) => el.items_center())
      .child(h_flex().id("settings").h(24).px(collapsed ? 0 : 8).gap(9).items_center().rounded(8)
        .when(collapsed, (el) => el.relative().w(32).justify_center().tooltip("Settings"))
        .text_color(t.muted).hover((el) => el.bg(t.hover).text_color(t.foreground)).cursor_pointer()
        .on_click(() => run("app.settings"))
        .child(svg("mods/workspace-chrome/settings.svg").size(14))
        .when(!collapsed, (el) => el.child("Settings"))
        .when(Boolean(updates().app.ready), (el) => el.child(collapsed ? ready.absolute().top(5).right(6) : ready)));
  }
}
