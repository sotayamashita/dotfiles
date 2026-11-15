import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, props, closeOverlay, openOverlay, theme, keys, spaces, panes, exec, notify } from "herdr";

function place(space) {
  const tabs = new Set(space.tabs.map((tab) => tab.id));

  return panes().find((pane) => tabs.has(pane.tab) && pane.cwd)?.cwd || space.folder;
}

async function checkout(folder, on) {
  const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd: folder, on });
  const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: folder, on });

  if (top.code !== 0 || common.code !== 0) return null;

  return common.stdout.trim() === `${top.stdout.trim()}/.git` ? "main" : "linked";
}

function items(git) {
  const id = props()?.target?.id;
  const space = spaces().find((entry) => entry.id === id);

  if (!space) return [];

  const folder = place(space);

  return [
    ["Rename", "space.rename", { id }],
    ...(space.machine == null && folder ? [["Open in Zed", "zed", { folder }]] : []),
    ...(git ? [["New worktree", "worktree", { space: id, action: "new" }], ["Open worktree", "worktree", { space: id, action: "open" }]] : []),
    ...(git === "linked" ? [["Remove worktree", "worktree", { space: id, action: "remove" }]] : []),
    ["Close", "space.close", { id }],
  ];
}

function menuIcon(command) {
  const name = command === "space.close" ? "x" : command === "space.rename" ? "square-pen" : command === "worktree" ? "git-branch" : "folder";

  return `mods/workspace-chrome/${name}.svg`;
}

function shortcut(name, args) {
  const value = Object.values(args)[0];
  const binding = keys().find((entry) => entry.section === "global" && (entry.action === name || entry.action === `${name}:${value}`));

  return binding ? binding.keys : "";
}

export default class SpaceMenu extends View {
  init(_props, cx) {
    this.at = 0;
    this.git = null;
    this.handle = cx.focus_handle();
    this.handle.focus();

    const space = spaces().find((entry) => entry.id === props()?.target?.id);
    const folder = space && place(space);

    if (folder) {
      cx.spawn(async (cx) => {
        this.git = await checkout(folder, space.machine).catch(() => null);
        cx.notify();
      });
    }
  }

  choose(index, cx) {
    const item = items(this.git)[index];

    if (!item) return;

    const [, command, args] = item;
    const overlay = props().overlay;

    if (command === "zed") {
      cx.spawn(async () => {
        try {
          const result = await exec("zed", [args.folder]);

          if (result.code !== 0) throw new Error(result.stderr.trim() || `Exit code: ${result.code}`);
        } catch (error) {
          notify({ title: "Failed to open Zed", body: error.message ?? String(error), level: "error" });
        } finally {
          closeOverlay(overlay);
        }
      });

      return;
    }

    closeOverlay(overlay);

    if (command === "worktree") {
      openOverlay({ mod: "worktree", kind: "dialog", ...(args.action === "open" ? { width: 560, height: 480 } : { width: 440, height: 260 }), props: args });
    } else {
      run(command, args);
    }
  }

  render() {
    const t = theme();
    const list = items(this.git);

    return v_flex().id("space-menu").track_focus(this.handle).w_full().min_h(0).p(5).bg(t.popover).text_size(12.8)
      .on_key_down((event, cx) => {
        if (event.key === "escape") closeOverlay(props().overlay);
        else if (!list.length) return;
        else if (event.key === "down") this.at = (this.at + 1) % list.length;
        else if (event.key === "up") this.at = (this.at + list.length - 1) % list.length;
        else if (event.key === "enter") this.choose(this.at, cx);
        else return;

        cx.notify();
      })
      .children(list.map(([label, command, args], index) => v_flex()
        .when(index > 0 && command === "space.close", (el) => el.child(div().mx(7).my(4).h(1).bg(t.border)))
        .child(h_flex().id(`space-menu-${index}`).h(31).px(8).gap(9).rounded(7).items_center().justify_between()
          .text_color(t.foreground)
          .when(index === this.at, (el) => el.bg(t.selected))
          .hover((el) => el.bg(t.hover))
          .on_click((_event, cx) => this.choose(index, cx))
          .child(svg(menuIcon(command)).size(14).flex_none().text_color(t.muted))
          .child(div().flex_1().child(label))
          .child(div().text_size(11).text_color(t.dim).child(shortcut(command, args))))));
  }
}
