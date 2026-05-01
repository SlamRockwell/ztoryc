#pragma once

#include "pane.h"

#include <QWidget>
#include <QString>
#include <QTextEdit>
#include <QLineEdit>
#include <QToolButton>
#include <QLabel>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QList>

//=============================================================================
// ZtoryScriptView — widget interno con testo e search
//=============================================================================

class ZtoryScriptView final : public QWidget {
  Q_OBJECT

public:
  explicit ZtoryScriptView(QWidget *parent = nullptr);

  void loadFile(const QString &filePath);
  void clear();

protected:
  void dragEnterEvent(QDragEnterEvent *e) override;
  void dropEvent(QDropEvent *e) override;

private slots:
  void onImportClicked();
  void onSearchTextChanged(const QString &text);
  void onSearchNext();
  void onSearchPrev();

private:
  // Parsing
  QString parseFdx(const QString &filePath);
  QString parseTxt(const QString &filePath);

  // Search helpers
  void applySearch(const QString &text);
  void navigateMatch(bool forward);

  // UI
  QToolButton  *m_importButton;
  QLineEdit    *m_searchField;
  QToolButton  *m_searchPrevBtn;
  QToolButton  *m_searchNextBtn;
  QLabel       *m_matchLabel;
  QTextEdit    *m_textEdit;

  // Search state
  QList<int>    m_matchPositions;
  int           m_currentMatch = -1;
  QString       m_lastSearch;
};

//=============================================================================
// ZtoryScriptPanel — TPanel wrapper dockabile
//=============================================================================

class ZtoryScriptPanel final : public TPanel {
  Q_OBJECT

public:
  explicit ZtoryScriptPanel(QWidget *parent = nullptr);

private:
  ZtoryScriptView *m_view;
};
