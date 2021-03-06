/**************************************************************************
 *   Butaca
 *   Copyright (C) 2011 - 2012 Simon Pena <spena@igalia.com>
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 **************************************************************************/

import QtQuick 1.1
import com.nokia.meego 1.1
import com.nokia.extras 1.1
import 'constants.js' as UIConstants
import 'moviedbwrapper.js' as TMDB

Page {
    id: galleryView

    property ListModel galleryViewModel
    property int currentIndex: -1
    property bool expanded: false

    property int imgType: TMDB.IMAGE_POSTER
    property int gridSize: 1
    property int fullSize: 4
    property int saveSize: 100

    tools: ToolBarLayout {
        ToolIcon {
            iconId: 'toolbar-back'
            onClicked: {
                if (expanded)
                    expanded = !expanded
                else
                    appWindow.pageStack.pop()
            }
        }

        ToolButton {
            anchors.centerIn: parent
            visible: expanded
            //: Placed on a tool button, when clicked opens a sheet to save the image
            text: qsTr('Save image')
            onClicked: {
                saveImageSheet.open()
            }
        }
    }

    Loader {
        sourceComponent: expanded ? detailedView : gridViewWrapper
        anchors.fill: parent
    }

    Component {
        id: gridViewWrapper

        GridView {
            id: gridView
            cellHeight: 160
            cellWidth: 160
            cacheBuffer: 2 * height
            model: galleryView.galleryViewModel
            delegate: Rectangle {
                id: gridViewDelegate
                height: cellHeight
                width: cellWidth
                color: '#2d2d2d'
                opacity: gridDelegateMouseArea.pressed ? 0.5 : 1

                Image {
                    id: gridDelegateImage
                    clip: true
                    anchors {
                        fill: parent
                        margins: UIConstants.PADDING_XSMALL
                    }
                    source: TMDB.image(imgType,
                                       gridSize,
                                       file_path,
                                       { app_locale: appLocale })
                    fillMode: Image.PreserveAspectCrop
                }

                Rectangle {
                    id: gridDelegateFrame
                    anchors.fill: parent
                    color: 'transparent'
                    border.color: '#2d2d2d'
                    border.width: UIConstants.PADDING_XSMALL
                }

                MouseArea {
                    id: gridDelegateMouseArea
                    anchors.fill: parent
                    onClicked: {
                        galleryView.currentIndex = index
                        galleryView.expanded = !galleryView.expanded
                    }
                }
            }
        }
    }

    Component {
        id: detailedView

        Rectangle {
            id: detailedDelegate
            color: '#2d2d2d'

            PageIndicator {
                id: detailedDelegateIndicator
                anchors {
                    top: parent.top
                    topMargin: UIConstants.DEFAULT_MARGIN
                    horizontalCenter: parent.horizontalCenter
                }
                totalPages: galleryView.galleryViewModel.count
                currentPage: galleryView.currentIndex + 1
            }

            ZoomableImage {
                id: detailedDelegateImage
                remoteSource: TMDB.image(imgType,
                                         fullSize,
                                         galleryView.galleryViewModel.get(galleryView.currentIndex).file_path,
                                         { app_locale: appLocale })
                anchors {
                    top: detailedDelegateIndicator.bottom
                    topMargin: UIConstants.DEFAULT_MARGIN
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                onSwipeLeft: {
                    galleryView.currentIndex = (galleryView.currentIndex + 1) %
                            galleryView.galleryViewModel.count
                }
                onSwipeRight: {
                    galleryView.currentIndex =
                            (galleryView.currentIndex - 1 +
                             galleryView.galleryViewModel.count) %
                            galleryView.galleryViewModel.count
                }
            }

            ProgressBar {
                id: detailedDelegateProgressBar
                anchors.centerIn: parent
                width: parent.width / 2
                minimumValue: 0
                maximumValue: 1
                value: detailedDelegateImage.progress
                visible: detailedDelegateImage.status === Image.Loading
            }
        }
    }

    Sheet {
        id: saveImageSheet

        property string imageUrl: galleryView.currentIndex >= 0 ?
                                      TMDB.image(imgType,
                                                 saveSize,
                                                 galleryView.galleryViewModel.get(galleryView.currentIndex).file_path,
                                                 { app_locale: appLocale }) :
                                      ''

        acceptButtonText:
            //: Placed on the save image sheet, when clicked actually saves the image
            qsTr('Save')
        rejectButtonText:
            //: Placed on the save image sheet, when clicked closes the sheet and doesn't save
            qsTr('Cancel')

        acceptButton.enabled: savingImage.status === Image.Ready

        buttons: BusyIndicator {
            anchors.centerIn: parent
            platformStyle: BusyIndicatorStyle {
                size: 'small'
            }
            visible: running
            running: savingImage.status === Image.Loading
        }

        content: Rectangle {
            id: saveImageContainer
            color: '#2d2d2d'
            anchors.fill: parent

            ZoomableImage {
                id: savingImage
                remoteSource: saveImageSheet.visible ?
                                  saveImageSheet.imageUrl :
                                  ''
                anchors.fill: parent
            }

            ProgressBar {
                id: savingImageProgressBar
                anchors.centerIn: parent
                width: parent.width / 2
                minimumValue: 0
                maximumValue: 1
                value: savingImage.progress
                visible: savingImage.status === Image.Loading
            }
        }
        onAccepted: {
            controller.saveImage(savingImage.image, saveImageSheet.imageUrl)
        }
    }
}
