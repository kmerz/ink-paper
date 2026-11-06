#!/usr/bin/env python3
"""Write the VS Code color themes (light + dark) from the ink-paper palette."""
import json
from pathlib import Path

P = {
    "light": dict(bg="#F2EEE6", surf="#E7E2D8", text="#1A1A1A", muted="#8A8580", acc="#B23A2E",
                  line="#DDD7CC", soft="#5C5853",
                  ansi=["#1A1A1A", "#B23A2E", "#5F6152", "#7D6E52", "#565D68", "#6B5A60", "#56625F", "#6E6A64",
                        "#8A8580", "#C8473A", "#717364", "#8F8064", "#69707B", "#7D6C72", "#687471", "#5C5853"]),
    "dark": dict(bg="#141414", surf="#1E1E1E", text="#E9E4DA", muted="#5C5853", acc="#C8473A",
                 line="#2A2826", soft="#8A8580",
                 ansi=["#1E1E1E", "#C8473A", "#8E907F", "#B3A283", "#858C96", "#9E8A92", "#869390", "#B8B2A8",
                       "#5C5853", "#C8473A", "#A3A593", "#C7B697", "#9AA1AB", "#B39FA7", "#9BA8A5", "#E9E4DA"]),
}
ANSI_NAMES = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]


def theme(mode, name):
    c = P[mode]
    a = c["ansi"]
    colors = {
        "focusBorder": c["acc"],
        "foreground": c["text"],
        "descriptionForeground": c["soft"],
        "errorForeground": c["acc"],
        "selection.background": c["muted"] + "55",
        "widget.shadow": "#00000022",
        "editor.background": c["bg"],
        "editor.foreground": c["text"],
        "editorCursor.foreground": c["acc"],
        "editor.selectionBackground": c["muted"] + "44",
        "editor.inactiveSelectionBackground": c["muted"] + "26",
        "editor.lineHighlightBackground": c["surf"],
        "editor.findMatchBackground": c["muted"] + "66",
        "editor.findMatchHighlightBackground": c["muted"] + "33",
        "editorLineNumber.foreground": c["muted"],
        "editorLineNumber.activeForeground": c["text"],
        "editorIndentGuide.background1": c["line"],
        "editorIndentGuide.activeBackground1": c["muted"],
        "editorWhitespace.foreground": c["line"],
        "editorRuler.foreground": c["line"],
        "editorBracketMatch.border": c["muted"],
        "editorBracketMatch.background": "#00000000",
        "editorError.foreground": c["acc"],
        "editorWarning.foreground": a[3],
        "editorInfo.foreground": a[4],
        "editorGutter.addedBackground": a[2],
        "editorGutter.modifiedBackground": a[3],
        "editorGutter.deletedBackground": c["acc"],
        "editorWidget.background": c["surf"],
        "editorWidget.border": c["line"],
        "editorSuggestWidget.background": c["surf"],
        "editorSuggestWidget.selectedBackground": c["muted"] + "44",
        "editorHoverWidget.background": c["surf"],
        "editorGroupHeader.tabsBackground": c["surf"],
        "editorGroup.border": c["line"],
        "tab.activeBackground": c["bg"],
        "tab.activeForeground": c["text"],
        "tab.activeBorderTop": c["acc"],
        "tab.inactiveBackground": c["surf"],
        "tab.inactiveForeground": c["soft"],
        "tab.border": c["line"],
        "titleBar.activeBackground": c["surf"],
        "titleBar.activeForeground": c["text"],
        "titleBar.inactiveBackground": c["surf"],
        "titleBar.inactiveForeground": c["muted"],
        "activityBar.background": c["surf"],
        "activityBar.foreground": c["text"],
        "activityBar.inactiveForeground": c["muted"],
        "activityBar.activeBorder": c["acc"],
        "activityBarBadge.background": c["text"],
        "activityBarBadge.foreground": c["bg"],
        "sideBar.background": c["surf"],
        "sideBar.foreground": c["text"],
        "sideBar.border": c["line"],
        "sideBarSectionHeader.background": c["surf"],
        "sideBarTitle.foreground": c["soft"],
        "list.activeSelectionBackground": c["muted"] + "44",
        "list.activeSelectionForeground": c["text"],
        "list.inactiveSelectionBackground": c["muted"] + "26",
        "list.hoverBackground": c["muted"] + "1A",
        "list.focusOutline": c["acc"],
        "list.highlightForeground": c["text"],
        "list.errorForeground": c["acc"],
        "statusBar.background": c["surf"],
        "statusBar.foreground": c["soft"],
        "statusBar.border": c["line"],
        "statusBar.noFolderBackground": c["surf"],
        "statusBar.debuggingBackground": c["acc"],
        "statusBar.debuggingForeground": c["bg"],
        "panel.background": c["bg"],
        "panel.border": c["line"],
        "panelTitle.activeBorder": c["acc"],
        "panelTitle.activeForeground": c["text"],
        "panelTitle.inactiveForeground": c["muted"],
        "input.background": c["bg"],
        "input.border": c["line"],
        "input.foreground": c["text"],
        "input.placeholderForeground": c["muted"],
        "dropdown.background": c["bg"],
        "dropdown.border": c["line"],
        "button.background": c["text"],
        "button.foreground": c["bg"],
        "button.hoverBackground": c["soft"],
        "button.secondaryBackground": c["surf"],
        "button.secondaryForeground": c["text"],
        "badge.background": c["text"],
        "badge.foreground": c["bg"],
        "progressBar.background": c["acc"],
        "scrollbarSlider.background": c["muted"] + "33",
        "scrollbarSlider.hoverBackground": c["muted"] + "55",
        "scrollbarSlider.activeBackground": c["muted"] + "77",
        "textLink.foreground": c["text"],
        "textLink.activeForeground": c["acc"],
        "gitDecoration.modifiedResourceForeground": a[3],
        "gitDecoration.untrackedResourceForeground": a[2],
        "gitDecoration.deletedResourceForeground": c["acc"],
        "gitDecoration.ignoredResourceForeground": c["muted"],
        "terminal.background": c["bg"],
        "terminal.foreground": c["text"],
        "terminalCursor.foreground": c["acc"],
        "terminal.selectionBackground": c["muted"] + "55",
    }
    for i, n in enumerate(ANSI_NAMES):
        colors[f"terminal.ansi{n}"] = a[i]
        colors[f"terminal.ansiBright{n}"] = a[i + 8]

    def tok(scope, fg, style=""):
        s = {"foreground": fg}
        if style:
            s["fontStyle"] = style
        return {"scope": scope, "settings": s}

    token_colors = [
        {"settings": {"foreground": c["text"], "background": c["bg"]}},
        tok(["comment", "punctuation.definition.comment"], c["muted"] if mode == "light" else "#8A8580", "italic"),
        tok(["keyword", "storage", "storage.type", "keyword.control"], c["text"], "bold"),
        tok(["keyword.operator", "punctuation"], c["soft"]),
        tok(["string", "string.quoted", "markup.inline.raw"], a[2]),
        tok(["constant.numeric", "constant.language", "constant.character", "support.constant"], a[3]),
        tok(["entity.name.type", "entity.name.class", "support.type", "support.class"], a[4]),
        tok(["entity.name.function", "support.function", "meta.function-call"], c["text"]),
        tok(["variable", "variable.parameter", "meta.definition.variable"], c["text"]),
        tok(["entity.name.tag"], c["text"], "bold"),
        tok(["entity.other.attribute-name"], a[4]),
        tok(["markup.heading", "entity.name.section"], c["text"], "bold"),
        tok(["markup.italic"], c["text"], "italic"),
        tok(["markup.bold"], c["text"], "bold"),
        tok(["markup.inserted"], a[2]),
        tok(["markup.deleted", "invalid", "invalid.illegal"], c["acc"]),
    ]
    return {
        "name": name,
        "type": mode,
        "semanticHighlighting": True,
        "colors": colors,
        "tokenColors": token_colors,
    }


if __name__ == "__main__":
    out = Path(__file__).resolve().parent / "themes"
    out.mkdir(exist_ok=True)
    (out / "ink-paper.json").write_text(json.dumps(theme("light", "Ink Paper"), indent=2))
    (out / "ink-dark.json").write_text(json.dumps(theme("dark", "Ink Dark"), indent=2))
    print("wrote", out)
