#pragma once

#ifndef VIEWERDRAW_INCLUDED
#define VIEWERDRAW_INCLUDED

//
// funzioni per il disegno (OpenGL) di oggetti
// che si vedono nel viewer
//

#include <vector>
#include "tgeometry.h"

// forward declaration
class SceneViewer;
class Ruler;
class TAffine;

//=============================================================================
// ViewerDraw
//-----------------------------------------------------------------------------

namespace ViewerDraw {

enum {  // cfr drawCamera()
  CAMERA_REFERENCE = 0X1,
  CAMERA_3D        = 0X2,
  SAFE_AREA        = 0X4,
  SOLID_LINE       = 0X8,
  SUBCAMERA        = 0X10
};

TRectD getCameraRect();

void drawCameraMask(SceneViewer *viewer);
void drawGridAndGuides(SceneViewer *viewer, double viewerScale, Ruler *vRuler,
                       Ruler *hRuler, bool gridEnabled);
void draw3DCamera(unsigned long flags, double zmin, double phi);
void drawCamera(unsigned long flags, double pixelSize);
void drawGridsAndOverlays(SceneViewer *viewer, double pixelSize);
void drawCameraOverlays(SceneViewer *viewer, double pixelSize);
void draw3DFrame(double zmin, double phi);
void drawDisk(int &tableDLId);
void drawDiskHoles();   // finger holes — drawn separately so the toggle works
void drawFieldGuide();

// Finger-hole constants (world units = Stage::inch * these values)
constexpr double kDiskHoleY_inch      = 7.0;  // distance from disk center
constexpr double kDiskHoleRadius_inch = 0.6;  // hit-test radius
void drawColorcard(UCHAR channel);
bool getShowFieldGuide();
void drawSafeArea();

unsigned int createDiskDisplayList();

}  // namespace

#endif
