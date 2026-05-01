#pragma once

#include "tundo.h"
#include "ztorymodel.h"
#include "toonz/txshlevel.h"

#include <QString>
#include <vector>

class StoryboardPanel;

// Snapshot of a single shot's state for undo/redo.
// TXshLevelP keeps the child level alive even after the xsheet column is deleted.
struct ZtoryShotSnap {
    ShotData   data;
    TXshLevelP level;
    int        duration;
};

// Generic undo item for Board CRUD operations.
// Stores full before/after snapshots and calls restoreFromSnapshot on undo/redo.
class UndoBoardState final : public TUndo {
    StoryboardPanel           *m_panel;
    QString                    m_label;
    std::vector<ZtoryShotSnap> m_before;
    std::vector<ZtoryShotSnap> m_after;
public:
    UndoBoardState(StoryboardPanel *panel, const QString &label,
                   std::vector<ZtoryShotSnap> before,
                   std::vector<ZtoryShotSnap> after)
        : m_panel(panel), m_label(label)
        , m_before(std::move(before)), m_after(std::move(after)) {}

    void    undo() const override;
    void    redo() const override;
    int     getSize() const override { return sizeof(*this); }
    QString getHistoryString() override { return m_label; }
};
