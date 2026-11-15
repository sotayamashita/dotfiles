import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, props, closeOverlay, openOverlay, theme, keys, spaces, panes, exec, notify } from "herdr";

function place(space) {
  const tabs = new Set(space.tabs.map((tab) => tab.id));

  return panes().find((pane) => tabs.has(pane.tab) && pane.cwd)?.cwd || space.folder;
}

async function checkout(folder, on) {
  const result = await exec("git", ["rev-parse", "--show-toplevel", "--path-format=absolute", "--git-common-dir"], { cwd: folder, on });

  if (result.code !== 0) return null;

  const [top, common] = result.stdout.trim().split(/\r?\n/);

  return common === `${top}/.git` ? "main" : "linked";
}

export default class SpaceMenu extends View {
  init(_props, cx) {
    this.at = 0;
    this.git = null;
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.space = spaces().find((entry) => entry.id === props()?.target?.id);
    this.folder = this.space && place(this.space);

    if (this.folder) {
      cx.spawn(async (cx) => {
        this.git = await checkout(this.folder, this.space.machine).catch(() => null);
        cx.notify();
      });
    }
  }

  items() {
    const { space, folder, git } = this;

    if (!space) return [];

    const id = space.id;
    const overlay = props()?.overlay;
    const command = (label, icon, name) => ({ label, icon, name, act: () => { closeOverlay(overlay); run(name, { id }); } });
    const worktree = (label, action, size) => ({ label, icon: "git-branch", act: () => {
      closeOverlay(overlay);
      openOverlay({ mod: "worktree", kind: "dialog", ...size, props: { space: id, action } });
    } });
    const zed = { label: "Open in Zed", icon: "folder", act: (cx) => cx.spawn(async () => {
      const result = await exec("zed", [folder]).catch((error) => ({ code: -1, stderr: error.message ?? String(error) }));

      if (result.code !== 0) notify({ title: "Failed to open Zed", body: result.stderr.trim() || `Exit code: ${result.code}`, level: "error" });

      closeOverlay(overlay);
    }) };

    return [
      command("Rename", "square-pen", "space.rename"),
      ...(space.machine == null && folder ? [zed] : []),
      ...(git ? [worktree("New worktree", "new", { width: 440, height: 260 }), worktree("Open worktree", "open", { width: 560, height: 480 })] : []),
      ...(git === "linked" ? [worktree("Remove worktree", "remove", { width: 440, height: 260 })] : []),
      command("Close", "x", "space.close"),
    ];
  }

  render() {
    const t = theme();
    const list = this.items();
    const bindings = keys().filter((entry) => entry.section === "global");

    return v_flex().id("space-menu").track_focus(this.handle).w_full().min_h(0).p(5).bg(t.popover).text_size(12.8)
      .on_key_down((event, cx) => {
        if (event.key === "escape") closeOverlay(props().overlay);
        else if (!list.length) return;
        else if (event.key === "down") this.at = (this.at + 1) % list.length;
        else if (event.key === "up") this.at = (this.at + list.length - 1) % list.length;
        else if (event.key === "enter") list[this.at].act(cx);
        else return;

        cx.notify();
      })
      .children(list.map((item, index) => v_flex()
        .when(item.name === "space.close", (el) => el.child(div().mx(7).my(4).h(1).bg(t.border)))
        .child(h_flex().id(`space-menu-${index}`).h(31).px(8).gap(9).rounded(7).items_center().justify_between()
          .text_color(t.foreground)
          .when(index === this.at, (el) => el.bg(t.selected))
          .hover((el) => el.bg(t.hover))
          .on_click((_event, cx) => item.act(cx))
          .child(svg(`mods/workspace-chrome/${item.icon}.svg`).size(14).flex_none().text_color(t.muted))
          .child(div().flex_1().child(item.label))
          .child(div().text_size(11).text_color(t.dim).child(bindings.find((entry) => entry.action === item.name)?.keys ?? "")))));
  }
}
