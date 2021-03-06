
//Copyright (C) Antti L S Ketola 2015 (antti.ketola at iki.fi)
//
//This file is part of ShopIt.

//ShopIt is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.

//ShopIt is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.

//You should have received a copy of the GNU General Public License
//along with ShopIt.  If not, see <http://www.gnu.org/licenses/>.

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "pages"
import "./dbaccess.js" as DBA

ApplicationWindow
{
    id: appWindow

    allowedOrientations: Orientation.All
    // Global context
    property int currIndex // a global for current shoppingListModel index, passed around
    property string currShop // DBA.unknownShop is the string value for an unassigned shop

    // constants
    property string wildcard: "*"

    property int refreshInterval: 900
    property bool webHelpEnabled: false

    // Declared here to be accessible thru appWindow.

    ListModel {
        id: shoppingListModel
    }

    ListModel {
        id: templistmodel
    }

    ListModel {
        id: shopModel
    }

    // Using Componentized declarations seem to reduce Silica Util.js:38
    // Errors (parent Null) - so the Component is the parent

    Component {
        id: listView
        SilicaListView {}
    }
    Component {
        id: itemeditflick
        SilicaFlickable {}
    }
    Component {
        id: firstPage
        FirstPage {}
    }

    Component {
        id: itemEditPage
        ItemEditPage {}
    }
    Component {
        id: itemAddPage
        ItemAddPage {}
    }
    Component {
        id: shopPage
        ShopPage {}
    }

    Component {
        id: settingsPage
        SettingsPage {}
    }

    // Back to normal business, the ApplicationWindow's pointer to start
    initialPage: firstPage

    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    // Noted that the toast rectangle doesn't turn according to
    // orientation without this
    onOrientationChanged: {
        switch(orientation) {
        case Orientation.Portrait:
            toast.rotation = 0
            break
        case Orientation.Landscape:
            toast.rotation = 90
            break
        case Orientation.PortraitInverted:
            toast.rotation = 180
            break
        case Orientation.LandscapeInverted:
            toast.rotation = 270
            break
        }
        //        console.log("appWindow.toast.rotation="+toast.rotation)
    }

    // This is a sort of application starting point
    Component.onCompleted: {
        console.log("harbour-ostos started")
        DBA.initDatabase(); // plug in localstorage
        currShop = wildcard
    }

    function setRefreshInterval(millisec) {
        if ((millisec >=0) && (millisec<=2000)){
            refreshInterval = millisec
        } else {
            refreshInterval = 300
        }
    }

    //     This timer is used to refresh the shopping list in a separate thread.
    Timer {
        id: menurefreshtimer
        interval: refreshInterval
        repeat: false

        property bool _enabler
        property string _current

        function turn_on(enabler,current) {
            console.log("harbour-ostos refresh timer start")
            //            console.debug("menurefreshtimer turn_on: enabler:"+enabler+" current:"+current)
            _enabler=enabler
            _current=current
            start()
            toast.show()
        }

        onTriggered: {

            stop()
            console.log("harbour-ostos refresh timer stop")
            if(_enabler){
                //                console.debug("menurefresh timer triggered.");
                refreshShoppingListByCurrentShop()

            } else {
                //                console.debug("menurefresh timer triggered and skipped; trace:"+ _current);
            }
            toast.hide()
        }
    }
    /*
     * Function to request refresh - without timer
     */
    function requestRefresh(enabler,tracetext) {
        //        console.debug("harbour-ostos.requestRefresh : enabler: "+enabler+"; trace:'"+tracetext)
        refreshShoppingListByCurrentShop()
    }
    /*
 * Function to request refresh asynchronously - the timer version spawning a new thread
 */
    function requestRefreshAsync(enabler,tracetext) {
        // console.debug("harbour-ostos.requestRefreshAsync : enabler: "+enabler+"; trace:'"+tracetext+"'")

        if (!menurefreshtimer.running) {
            menurefreshtimer.turn_on(enabler,tracetext)
        } else {
            menurefreshtimer.restart()
            //            console.debug("harbour-ostos.requestRefresh - restarted timer.")
        }
    }

    // This is for "painting" the first page
    function  refreshShoppingListByCurrentShop(){
        if ((currShop==wildcard) || (!currShop) ) {
            currShop=wildcard
            shoppingListModel.clear()
            DBA.readShoppingListExState(shoppingListModel,"HIDE");
        } else {
            shoppingListModel.clear()
            DBA.readShoppingListByShopExState(shoppingListModel, currShop,"HIDE");
        }
        //        console.log("By Current shopname="+currShop)
    }

    // This is the small dark square to stop
    // the user desperately waiting for the list update
    Rectangle {
        id: toast

        color: "#"+(~(valueOf(Theme.primaryColor))) // a snappy way to calculate inverse color
        opacity: 20
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 5
        width: toastLabel.width+Theme.paddingLarge
        height: 0                 // Start as hidden, Transition will bring it visible

        Label {
            id: toastLabel   // the text to taunt the user

            visible: parent.visible
            color: Theme.primaryColor
            opacity: 100
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: qsTr("Updating")
        }

        states: State {
            name: "toasting"; when: visible
            PropertyChanges {
                target: toast; height: Theme.itemSizeMedium
            }
        }

        transitions: Transition {
            to: "toasting"
            ParallelAnimation {
                PropertyAnimation {
                    target: toast
                    properties: "height";
                    from: 0
                    duration: 300
                    easing.type: Easing.OutBack
                }
                PropertyAnimation {
                    target: toastLabel
                    properties: "font.pixelSize"
                    duration: 300
                    from:0
                    to: Theme.fontSizeMedium
                    easing.type: Easing.OutBack
                }
                PropertyAnimation {
                    target: toastLabel
                    properties: "opacity"
                    duration: 200
                    from:0
                    to: 100
                }
            }
        }

        function show() {
            //            console.log("***show toast")
            visible=true
            state = "toasting"
        }

        function hide() {
            //            console.log("***hide toast")
            visible=false
            state=""

        }

        Component.onCompleted: {
            visible=false
            state=""
        }
    } // end Rectangle
}


