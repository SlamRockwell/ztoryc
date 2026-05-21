#include "ztoryscriptpanel.h"

#include "ztorymodel.h"
#include "tapp.h"
#include "toonz/tscenehandle.h"
#include "toonz/toonzscene.h"
#include "tsystem.h"
#include "tfilepath.h"

#include <QFileDialog>
#include <QFileInfo>
#include <QFile>
#include <QTextStream>
#include <QTextCodec>
#include <QDragEnterEvent>
#include <QDropEvent>
#include <QMimeData>
#include <QUrl>
#include <QXmlStreamReader>
#include <QScrollBar>
#include <QTextCursor>
#include <QTextCharFormat>
#include <QColor>
#include <QFont>
#include <QSizePolicy>
#include <QPalette>

//=============================================================================
// ZtoryScriptView
//=============================================================================

ZtoryScriptView::ZtoryScriptView(QWidget *parent)
    : QWidget(parent) {

  // --- Toolbar superiore ---
  m_importButton = new QToolButton(this);
  m_importButton->setText(tr("Import…"));
  m_importButton->setToolTip(tr("Import screenplay (.fdx, .txt)"));
  m_importButton->setFixedHeight(24);

  m_searchField = new QLineEdit(this);
  m_searchField->setPlaceholderText(tr("Search…"));
  m_searchField->setFixedHeight(24);
  m_searchField->setClearButtonEnabled(true);

  m_searchPrevBtn = new QToolButton(this);
  m_searchPrevBtn->setText("▲");
  m_searchPrevBtn->setFixedSize(24, 24);
  m_searchPrevBtn->setToolTip(tr("Previous match"));
  m_searchPrevBtn->setEnabled(false);

  m_searchNextBtn = new QToolButton(this);
  m_searchNextBtn->setText("▼");
  m_searchNextBtn->setFixedSize(24, 24);
  m_searchNextBtn->setToolTip(tr("Next match"));
  m_searchNextBtn->setEnabled(false);

  m_matchLabel = new QLabel(this);
  m_matchLabel->setFixedWidth(60);
  m_matchLabel->setAlignment(Qt::AlignCenter);
  m_matchLabel->setStyleSheet("color: #888; font-size: 11px;");

  QHBoxLayout *toolbar = new QHBoxLayout;
  toolbar->setContentsMargins(4, 4, 4, 4);
  toolbar->setSpacing(4);
  toolbar->addWidget(m_importButton);
  toolbar->addSpacing(8);
  toolbar->addWidget(m_searchField);
  toolbar->addWidget(m_searchPrevBtn);
  toolbar->addWidget(m_searchNextBtn);
  toolbar->addWidget(m_matchLabel);

  // --- Area testo ---
  m_textEdit = new QTextEdit(this);
  m_textEdit->setReadOnly(true);
  m_textEdit->setLineWrapMode(QTextEdit::NoWrap);  // prevents zero-width layout recursion
  m_textEdit->setMinimumSize(80, 60);
  m_textEdit->setFont(QFont("Courier", 11));
  m_textEdit->setStyleSheet(
      "QTextEdit { background: #1e1e1e; color: #d4d4d4; "
      "border: none; padding: 8px; }");
  m_textEdit->setPlaceholderText(
      tr("Import a screenplay file (.fdx or .txt) to start reading."));

  // --- Layout principale ---
  QVBoxLayout *main = new QVBoxLayout(this);
  main->setContentsMargins(0, 0, 0, 0);
  main->setSpacing(0);
  main->addLayout(toolbar);
  main->addWidget(m_textEdit);
  setLayout(main);

  setAcceptDrops(true);

  // --- Connessioni ---
  connect(m_importButton, &QToolButton::clicked,
          this, &ZtoryScriptView::onImportClicked);
  connect(m_searchField, &QLineEdit::textChanged,
          this, &ZtoryScriptView::onSearchTextChanged);
  connect(m_searchNextBtn, &QToolButton::clicked,
          this, &ZtoryScriptView::onSearchNext);
  connect(m_searchPrevBtn, &QToolButton::clicked,
          this, &ZtoryScriptView::onSearchPrev);

  // Keep the screenplay in sync with the current scene: ZtoryModel::load()
  // emits modelReset() after reading the .ztoryc, and the scene handle emits
  // sceneSwitched on every scene change.  Either way reloadFromModel() shows
  // the new scene's screenplay (or clears the panel when there is none).
  connect(ZtoryModel::instance(), &ZtoryModel::modelReset,
          this, &ZtoryScriptView::reloadFromModel);
  connect(TApp::instance()->getCurrentScene(), &TSceneHandle::sceneSwitched,
          this, &ZtoryScriptView::reloadFromModel);
}

//-----------------------------------------------------------------------------

void ZtoryScriptView::importScreenplay(const QString &srcPath) {
  if (srcPath.isEmpty()) return;
  ToonzScene *scene = TApp::instance()->getCurrentScene()->getScene();
  if (!scene) {
    // No scene yet — just display it without persisting.
    m_currentFilePath = srcPath;
    loadFile(srcPath);
    return;
  }
  TFilePath src(srcPath.toStdWString());
  // Destination: the project's +extras/script folder.
  TFilePath destDir = scene->decodeFilePath(TFilePath("+extras")) + "script";
  TFilePath dest    = destDir + src.withoutParentDir();
  if (src != dest) {
    try {
      TSystem::touchParentDir(dest);
      TSystem::copyFileOrLevel_throw(dest, src);
    } catch (...) {
      // Copy failed (permissions, missing source…): fall back to the original
      // path so the user at least sees the screenplay this session.
      m_currentFilePath = srcPath;
      loadFile(srcPath);
      return;
    }
  }
  // Persist a project-relative path ("+extras/script/<file>") in the .ztoryc.
  ZtoryModel::instance()->setScriptFile(scene->codeFilePath(dest).getQString());
  m_currentFilePath = dest.getQString();
  loadFile(m_currentFilePath);
}

//-----------------------------------------------------------------------------

void ZtoryScriptView::reloadFromModel() {
  QString rel = ZtoryModel::instance()->scriptFile();
  if (rel.isEmpty()) {
    // Current scene has no screenplay — clear any leftover from a prior scene.
    if (!m_currentFilePath.isEmpty()) {
      clear();
      m_currentFilePath.clear();
    }
    return;
  }
  ToonzScene *scene = TApp::instance()->getCurrentScene()->getScene();
  if (!scene) return;
  TFilePath abs = scene->decodeFilePath(TFilePath(rel.toStdWString()));
  QString absStr = abs.getQString();
  if (absStr == m_currentFilePath) return;  // already showing this screenplay
  if (TFileStatus(abs).doesExist()) {
    m_currentFilePath = absStr;
    loadFile(absStr);
  } else {
    clear();
    m_currentFilePath.clear();
  }
}

//-----------------------------------------------------------------------------

void ZtoryScriptView::dragEnterEvent(QDragEnterEvent *e) {
  if (!e->mimeData()->hasUrls()) { e->ignore(); return; }
  for (const QUrl &url : e->mimeData()->urls()) {
    QString path = url.toLocalFile().toLower();
    if (path.endsWith(".fdx") || path.endsWith(".txt")) {
      e->acceptProposedAction();
      return;
    }
  }
  e->ignore();
}

void ZtoryScriptView::dropEvent(QDropEvent *e) {
  for (const QUrl &url : e->mimeData()->urls()) {
    QString path = url.toLocalFile();
    if (path.endsWith(".fdx", Qt::CaseInsensitive) ||
        path.endsWith(".txt", Qt::CaseInsensitive)) {
      importScreenplay(path);
      e->acceptProposedAction();
      return;
    }
  }
}

void ZtoryScriptView::onImportClicked() {
  // nullptr parent: prevents dialog from appearing behind the main window
  // on macOS when the panel is docked or embedded in a complex widget hierarchy.
  QString filePath = QFileDialog::getOpenFileName(
      nullptr,
      tr("Import Screenplay"),
      QString(),
      tr("Screenplay files (*.fdx *.txt);;Final Draft (*.fdx);;Text (*.txt)"));

  if (filePath.isEmpty()) return;
  importScreenplay(filePath);
}

//-----------------------------------------------------------------------------

void ZtoryScriptView::loadFile(const QString &filePath) {
  QString content;

  if (filePath.endsWith(".fdx", Qt::CaseInsensitive)) {
    content = parseFdx(filePath);
  } else {
    content = parseTxt(filePath);
  }

  if (content.isEmpty()) {
    m_textEdit->setPlaceholderText(tr("Could not read file or file is empty."));
    return;
  }

  m_textEdit->setPlainText(content);

  // Reset search
  m_searchField->clear();
  m_matchPositions.clear();
  m_currentMatch = -1;
  m_matchLabel->clear();
  m_searchPrevBtn->setEnabled(false);
  m_searchNextBtn->setEnabled(false);
}

//-----------------------------------------------------------------------------

void ZtoryScriptView::clear() {
  m_textEdit->clear();
  m_searchField->clear();
  m_matchPositions.clear();
  m_currentMatch = -1;
  m_matchLabel->clear();
}

//-----------------------------------------------------------------------------
// FDX parser — Final Draft XML
// Legge solo i nodi <Text> dentro <Paragraph>, preservando il tipo
// (Scene Heading, Action, Character, Dialogue, Transition…)
//-----------------------------------------------------------------------------

QString ZtoryScriptView::parseFdx(const QString &filePath) {
  QFile file(filePath);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return QString();

  QString result;
  QXmlStreamReader xml(&file);

  QString currentType;
  QString currentText;

  while (!xml.atEnd() && !xml.hasError()) {
    xml.readNext();

    if (xml.isStartElement()) {
      if (xml.name() == QLatin1String("Paragraph")) {
        currentType = xml.attributes().value("Type").toString();
        currentText.clear();
      } else if (xml.name() == QLatin1String("Text")) {
        currentText += xml.readElementText();
      }
    } else if (xml.isEndElement()) {
      if (xml.name() == QLatin1String("Paragraph") && !currentText.trimmed().isEmpty()) {
        // Formattazione visiva per tipo
        if (currentType == "Scene Heading") {
          result += "\n" + currentText.trimmed().toUpper() + "\n";
        } else if (currentType == "Action") {
          result += "\n" + currentText.trimmed() + "\n";
        } else if (currentType == "Character") {
          result += "\n          " + currentText.trimmed().toUpper() + "\n";
        } else if (currentType == "Dialogue") {
          result += "     " + currentText.trimmed() + "\n";
        } else if (currentType == "Parenthetical") {
          result += "     (" + currentText.trimmed() + ")\n";
        } else if (currentType == "Transition") {
          result += "\n                              "
                    + currentText.trimmed().toUpper() + "\n";
        } else {
          result += currentText.trimmed() + "\n";
        }
        currentText.clear();
      }
    }
  }

  file.close();
  return result;
}

//-----------------------------------------------------------------------------
// TXT parser — testo plain, lettura diretta
//-----------------------------------------------------------------------------

QString ZtoryScriptView::parseTxt(const QString &filePath) {
  QFile file(filePath);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return QString();

  QTextStream stream(&file);
  stream.setCodec("UTF-8");
  QString content = stream.readAll();
  file.close();
  return content;
}

//-----------------------------------------------------------------------------
// Search
//-----------------------------------------------------------------------------

void ZtoryScriptView::onSearchTextChanged(const QString &text) {
  applySearch(text);
}

void ZtoryScriptView::applySearch(const QString &text) {
  // Rimuovi highlight precedente
  QTextCursor cursor = m_textEdit->textCursor();
  cursor.select(QTextCursor::Document);
  QTextCharFormat plainFormat;
  plainFormat.setBackground(Qt::transparent);
  cursor.setCharFormat(plainFormat);
  cursor.clearSelection();
  m_textEdit->setTextCursor(cursor);

  m_matchPositions.clear();
  m_currentMatch = -1;
  m_matchLabel->clear();

  if (text.isEmpty()) {
    m_searchPrevBtn->setEnabled(false);
    m_searchNextBtn->setEnabled(false);
    return;
  }

  // Trova tutte le occorrenze
  QTextDocument *doc = m_textEdit->document();
  QTextCharFormat highlightFormat;
  highlightFormat.setBackground(QColor("#4a4a00"));
  highlightFormat.setForeground(QColor("#ffff88"));

  QTextCursor search(doc);
  while (!search.isNull() && !search.atEnd()) {
    search = doc->find(text, search, QTextDocument::FindCaseSensitively);
    if (!search.isNull()) {
      m_matchPositions.append(search.anchor());
      search.mergeCharFormat(highlightFormat);
    }
  }

  int count = m_matchPositions.size();
  if (count > 0) {
    m_currentMatch = 0;
    navigateMatch(true);
    m_matchLabel->setText(QString("1/%1").arg(count));
    m_searchPrevBtn->setEnabled(true);
    m_searchNextBtn->setEnabled(true);
  } else {
    m_matchLabel->setText(tr("0 found"));
    m_searchPrevBtn->setEnabled(false);
    m_searchNextBtn->setEnabled(false);
  }
  m_lastSearch = text;
}

void ZtoryScriptView::onSearchNext() {
  if (m_matchPositions.isEmpty()) return;
  m_currentMatch = (m_currentMatch + 1) % m_matchPositions.size();
  navigateMatch(true);
  m_matchLabel->setText(
      QString("%1/%2").arg(m_currentMatch + 1).arg(m_matchPositions.size()));
}

void ZtoryScriptView::onSearchPrev() {
  if (m_matchPositions.isEmpty()) return;
  m_currentMatch = (m_currentMatch - 1 + m_matchPositions.size())
                   % m_matchPositions.size();
  navigateMatch(false);
  m_matchLabel->setText(
      QString("%1/%2").arg(m_currentMatch + 1).arg(m_matchPositions.size()));
}

void ZtoryScriptView::navigateMatch(bool forward) {
  if (m_matchPositions.isEmpty() || m_currentMatch < 0) return;

  int pos = m_matchPositions[m_currentMatch];
  QTextDocument *doc = m_textEdit->document();

  // Highlight corrente in giallo brillante
  QTextCursor cur(doc);
  cur.setPosition(pos);
  cur.movePosition(QTextCursor::Right, QTextCursor::KeepAnchor,
                   m_lastSearch.length());

  QTextCharFormat currentFormat;
  currentFormat.setBackground(QColor("#aaaa00"));
  currentFormat.setForeground(QColor("#ffffff"));
  cur.mergeCharFormat(currentFormat);

  m_textEdit->setTextCursor(cur);
  m_textEdit->ensureCursorVisible();
}

//=============================================================================
// ZtoryScriptPanel
//=============================================================================

ZtoryScriptPanel::ZtoryScriptPanel(QWidget *parent)
    : TPanel(parent) {
  setWindowTitle(tr("Ztoryc Script"));
  setObjectName("ZtoryScriptPanel");

  m_view = new ZtoryScriptView(this);
  setWidget(m_view);

  // Dimensione di default ragionevole
  setMinimumSize(320, 400);
  resize(420, 600);
}

//=============================================================================
// Factory
//=============================================================================

class ZtoryScriptPanelFactory final : public TPanelFactory {
public:
  ZtoryScriptPanelFactory() : TPanelFactory("ZtoryScriptPanel") {}
  TPanel *createPanel(QWidget *parent) override {
    TPanel *panel = new ZtoryScriptPanel(parent);
    panel->setObjectName("ZtoryScriptPanel");
    panel->setWindowTitle("Ztoryc Script");
    return panel;
  }
  void initialize(TPanel *) override { assert(0); }
} ztoryScriptPanelFactory;
