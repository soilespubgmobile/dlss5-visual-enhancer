pragma ComponentBehavior: Bound
import QtQuick
import QtMultimedia
import QtQuick.Window
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import VisualEnhancer 1.0
import ".."
import "../controls"
import "../components"

Item {
    id: root
    objectName: "compare-view"
    property var appBridge: null
    readonly property var compare: appBridge ? appBridge.compare : null
    readonly property var opts: compare ? compare.options : ({})
    readonly property var sources: compare ? compare.sources : []
    readonly property bool editable: compare && !compare.loading && !compare.busy
    readonly property bool textEditing: root.Window.window && (root.Window.window.activeFocusItem instanceof TextInput || root.Window.window.activeFocusItem instanceof TextEdit)
    property bool controlTapArmed: false
    Keys.enabled:root.visible&&root.editable&&!root.textEditing&&root.opts.layout==="clicker"
    Keys.onPressed:event=>{
        if(event.key===Qt.Key_Control&&!event.isAutoRepeat){root.controlTapArmed=true;event.accepted=true}
        else if(event.key!==Qt.Key_Control)root.controlTapArmed=false
    }
    Keys.onReleased:event=>{
        if(event.key===Qt.Key_Control&&!event.isAutoRepeat){if(root.controlTapArmed)root.compare.cycleSource(-1);root.controlTapArmed=false;event.accepted=true}
    }
    onVisibleChanged:controlTapArmed=false
    onTextEditingChanged:if(textEditing)controlTapArmed=false
    property bool listCollapsed: true
    property real listHeight: 330
    readonly property bool exportVideo: compare ? compare.hasVideo : false
    property int previousSourceCount: 0
    onSourcesChanged: {
        // Match Neural Rendering: empty starts collapsed, additions reveal the
        // queue, and ordinary source updates preserve the user's last choice.
        if(sources.length!==previousSourceCount) {
            if(sources.length===0||sources.length>previousSourceCount)
                listCollapsed=sources.length===0
            previousSourceCount=sources.length
        }
    }
    property string draggedId: ""
    property bool draggingRow: false
    property real dragListY: 0
    property int dropIndex: -1
    function option(key, value) { if (compare) compare.setOption(key, value) }
    function indexForId(id) { for (var i=0; i<sources.length; ++i) if (sources[i].id===id) return i; return -1 }
    function sourceChoices() {
        var result=[]
        for (var i=0; i<sources.length; ++i) if(sources[i].visible) result.push({label:sources[i].label+" · "+sources[i].resolution+" · "+sources[i].name,value:sources[i].id})
        return result
    }
    function updateDrop() { dropIndex=sourceList.indexAt(1,sourceList.contentY+dragListY) }
    function openExport(video) { var error=compare.exportConfigured(video); exportSettings.errorMessage=error; if(!error)exportSettings.close() }
    function openSourceMenu(id, item, x, y) {
        if (!editable || indexForId(id) < 0) return
        compare.selectSource(id)
        sourceMenu.sourceId = id
        var point = item.mapToItem(root, x, y)
        sourceMenu.popup(point.x, point.y)
    }
    QQC2.Menu {
        id: sourceMenu
        objectName: "compareContextMenu"
        property string sourceId: ""
        readonly property int sourceIndex: root.indexForId(sourceId)
        readonly property var source: sourceIndex >= 0 ? root.sources[sourceIndex] : ({})
        leftInset: 0
        rightInset: 0
        topInset: 0
        bottomInset: 0
        topPadding: 3
        bottomPadding: 3
        leftPadding: 3
        rightPadding: 3
        spacing: 1

        TextMetrics {
            id: compareMenuMetrics
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBody
            text: qsTranslate("App", "Show in Explorer")
        }

        background: Rectangle {
            color: Theme.bgSurface
            border.color: Theme.borderDefault
            border.width: 1
            radius: Theme.radiusSmall
            implicitWidth: Math.max(150, Math.ceil(compareMenuMetrics.width) + 48)
        }

        component SourceMenuItem: QQC2.MenuItem {
            id: compareMi
            implicitHeight: 25
            leftPadding: 10
            rightPadding: 10
            indicator: null
            contentItem: Text {
                text: compareMi.text
                color: !compareMi.enabled ? Theme.textMuted : (compareMi.highlighted ? Theme.textPrimary : Theme.textSecondary)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                font.weight: Font.Normal
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: compareMi.highlighted && compareMi.enabled ? Theme.bgHover : "transparent"
                radius: 3
            }
        }

        SourceMenuItem {
            implicitHeight: 25
            objectName: "compareContextClear"
            text: sourceMenu.source.video ? qsTranslate("App", "Clear video") : qsTranslate("App", "Clear image")
            enabled: sourceMenu.sourceIndex >= 0 && root.editable
            onTriggered: { if (root.editable && sourceMenu.sourceIndex >= 0) root.compare.removeSource(sourceMenu.sourceIndex) }
        }
        SourceMenuItem {
            implicitHeight: 25
            objectName: "compareContextClearAll"
            text: qsTranslate("App", "Clear all")
            enabled: sourceMenu.sourceIndex >= 0 && root.editable
            onTriggered: { if (root.editable) root.compare.clear() }
        }
        SourceMenuItem {
            implicitHeight: 25
            text: qsTranslate("App", "Show in Explorer")
            enabled: sourceMenu.sourceIndex >= 0 && root.appBridge
            onTriggered: { if (root.appBridge && sourceMenu.sourceIndex >= 0) root.appBridge.showInExplorer(sourceMenu.source.path) }
        }
    }
    function timeText(seconds) { var s=Math.max(0,seconds||0); return Math.floor(s/60).toString().padStart(2,"0")+":"+(s%60).toFixed(2).padStart(5,"0") }

    Shortcut { sequence:"Ctrl+O"; enabled:root.visible&&root.editable&&!root.textEditing; onActivated:{root.controlTapArmed=false;files.open()} }
    Shortcut { sequence:"Ctrl+V"; enabled:root.visible&&root.editable&&!root.textEditing; onActivated:{root.controlTapArmed=false;root.compare.pasteSources()} }
    Shortcut { sequence:"Space"; enabled:root.visible&&root.editable&&(root.opts.layout==="clicker"||root.compare.hasVideo)&&!root.textEditing; onActivated:{root.controlTapArmed=false;if(root.opts.layout==="clicker")root.compare.cycleSource(1);else root.compare.togglePlayback()} }
    Shortcut { sequence:"Right"; enabled:root.visible&&root.editable&&!root.textEditing; onActivated:{if(root.opts.layout==="clicker")root.compare.cycleSource(1);else if(root.compare.hasVideo)root.compare.step(1)} }
    Shortcut { sequence:"Left"; enabled:root.visible&&root.editable&&!root.textEditing; onActivated:{if(root.opts.layout==="clicker")root.compare.cycleSource(-1);else if(root.compare.hasVideo)root.compare.step(-1)} }

    // Adapt Compare's synchronized clock to the shared transport's millisecond
    // interface. No additional video player is created.
    QtObject {
        id:comparePlayback
        readonly property real origin:root.compare?root.compare.rangeStart:0
        readonly property real duration:root.compare?Math.max(0,root.compare.rangeEnd-origin)*1000:0
        readonly property real position:root.compare?(root.compare.position-origin)*1000:0
        readonly property int playbackState:root.compare&&root.compare.playing?MediaPlayer.PlayingState:MediaPlayer.PausedState
        property real playbackRate:root.opts.speed||1
        onPlaybackRateChanged:root.option("speed",playbackRate)
        function seekToPosition(ms){if(root.compare)root.compare.seek(origin+ms/1000)}
        function play(){if(root.compare&&!root.compare.playing)root.compare.togglePlayback()}
        function pause(){if(root.compare&&root.compare.playing)root.compare.togglePlayback()}
    }

    Connections {
        target:root.compare
        function onOptionsChanged(){comparePlayback.playbackRate=Number(root.opts.speed||1)}
    }

    QtObject {
        id:exportBridge
        property string nrMode:root.exportVideo?"Video":"Image"
        readonly property var imageFormatChoices:root.appBridge?root.appBridge.imageFormatChoices:[]
        readonly property var compatibleVideoCodecChoices:["H.264","H.264 (NVIDIA NVENC)","H.265","H.265 (NVIDIA NVENC)","AV1","AV1 (NVIDIA NVENC)","VP9","ProRes Proxy","ProRes HQ","FFV1 Lossless RGB 10-bit"]
        readonly property var containerChoices:videoCodec==="VP9"?["WEBM","MKV","MP4"]:videoCodec.indexOf("ProRes")===0?["MOV","MKV"]:videoCodec.indexOf("FFV1")===0?["MKV"]:videoCodec.indexOf("AV1")===0?["MP4","MKV","WEBM"]:["MP4","MKV","MOV"]
        readonly property var fixedQualityCodecs:root.appBridge?root.appBridge.fixedQualityCodecs:[]
        readonly property var encodingQualityChoices:root.appBridge?root.appBridge.encodingQualityChoices:[]
        property string imageFormat:root.opts.imageFormat||"PNG"
        onImageFormatChanged:{root.option("imageFormat",imageFormat);if(["PNG","TIFF","JPEG XL"].indexOf(imageFormat)<0)root.option("bitDepth",8)}
        property int imageBitDepth:root.opts.bitDepth||8
        onImageBitDepthChanged:root.option("bitDepth",imageBitDepth)
        property int imageQuality:root.opts.imageQuality||95
        onImageQualityChanged:root.option("imageQuality",imageQuality)
        property bool imageJxlLossless:root.opts.jxlLossless||false
        onImageJxlLosslessChanged:root.option("jxlLossless",imageJxlLossless)
        property int imageJxlEffort:root.opts.jxlEffort||7
        onImageJxlEffortChanged:root.option("jxlEffort",imageJxlEffort)
        property bool imageJxlProgressive:root.opts.jxlProgressive||false
        onImageJxlProgressiveChanged:root.option("jxlProgressive",imageJxlProgressive)
        property string videoCodec:(root.opts.codec||"H.264").replace(" (CPU)","").replace(/^FFV1$/, "FFV1 Lossless RGB 10-bit")
        onVideoCodecChanged: Qt.callLater(function() {
            root.option("codec", exportBridge.videoCodec)
            const saved = (root.opts.container || "mp4").toUpperCase()
            const selected = exportBridge.containerChoices.includes(saved) ? saved : exportBridge.containerChoices[0]
            if (exportBridge.videoContainer !== selected)
                exportBridge.videoContainer = selected
        })
        property string videoContainer:(root.opts.container||"mp4").toUpperCase()
        onVideoContainerChanged:root.option("container",videoContainer.toLowerCase())
        property string videoQuality:root.opts.quality||"Best"
        onVideoQualityChanged:root.option("quality",videoQuality)
        readonly property bool videoHdrMode:false
        readonly property bool videoHdrSupported:false
        readonly property string renderValidationMessage:""
    }
    FileDialog {
        id: files
        title:qsTranslate("App","Add comparison sources"); fileMode:FileDialog.OpenFiles
        nameFilters:[qsTranslate("App","Images and videos (*.png *.jpg *.jpeg *.webp *.tif *.tiff *.bmp *.avif *.jxl *.heic *.heif *.exr *.dng *.raw *.cr2 *.cr3 *.nef *.arw *.mp4 *.mkv *.mov *.avi *.webm *.m4v *.mts *.m2ts *.wmv)"),qsTranslate("App","All Files (*.*)")]
        onAccepted:root.compare.addSources(selectedFiles)
    }
    FolderDialog {id:compareExportFolder;title:qsTranslate("App","Select Export Folder");onAccepted:root.option("exportFolder",selectedFolder.toString())}

    Rectangle {
        id: mainArea
        anchors { left:parent.left; right:parent.right; top:parent.top; bottom:parent.bottom }
        color:Theme.bgBase
        Rectangle {
            id:toolbar
            anchors {left:parent.left;right:parent.right;top:parent.top}
            visible:root.sources.length>0
            readonly property bool stacked:width<1100
            height:visible?(stacked?selectors.height+50:Math.max(selectors.height,28)+16)+(pairSelectors.visible&&!pairSelectors.inlinePair?34:0):0
            color:"#E014171D";border.color:Theme.borderSubtle
            Flow {
                id:selectors;x:10;y:8;spacing:8
                width:toolbar.stacked?toolbar.width-20:toolbarActions.x-20
                AppSegmentedControl {
                    objectName:"compareModeSelector";width:Math.min(400,selectors.width)
                    model:[{label:qsTranslate("App","Side by Side"),value:"side"},{label:qsTranslate("App","Cycle"),value:"clicker"},{label:qsTranslate("App","Split View"),value:"slider"},{label:qsTranslate("App","Difference"),value:"difference"}]
                    currentValue:root.opts.layout;enabled:root.editable;onActivated:value=>{root.option("layout",value);navigation.forceActiveFocus()}
                }
                AppSegmentedControl {
                    width:Math.min(330,selectors.width)
                    model:[{label:qsTranslate("App","Match Tallest"),value:"largest"},{label:qsTranslate("App","Manual Scale"),value:"standard"},{label:qsTranslate("App","Match Shortest"),value:"smallest"}]
                    currentValue:root.opts.sizeMatch;enabled:root.editable;onActivated:value=>root.option("sizeMatch",value)
                }
                Text {
                    width:220;height:26;verticalAlignment:Text.AlignVCenter;visible:toolbar.width>=1400&&root.opts.layout!=="slider"&&root.opts.layout!=="difference"
                    text:root.compare&&root.compare.selectedSource?root.compare.selectedSource.label+"   "+root.compare.selectedSource.resolution+"   "+root.compare.selectedSource.name:""
                    color:Theme.textSecondary;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeBody;elide:Text.ElideMiddle
                }
            }
            Row {
                id:pairSelectors;objectName:"comparePairSelectors"
                anchors.horizontalCenter:parent.horizontalCenter
                readonly property bool inlinePair:!toolbar.stacked&&x>=760&&x+width<toolbarActions.x-12
                y:inlinePair?8:selectors.height+16
                    visible:(root.opts.layout==="slider"||root.opts.layout==="difference")&&root.sources.length>1
                    width:Math.min(640,toolbar.width-20);spacing:6
                    AppComboBox {width:(parent.width-40)/2;comboHeight:26;currentValue:root.opts.pairA;model:root.sourceChoices();enabled:root.editable;onActivated:id=>root.compare.assignPair(0,id)}
                    AppIconButton {iconName:"compare";buttonSize:26;tooltipText:qsTranslate("App","Swap sides");enabled:root.editable;onClicked:root.compare.swapPair()}
                    AppComboBox {width:(parent.width-40)/2;comboHeight:26;currentValue:root.opts.pairB;model:root.sourceChoices();enabled:root.editable;onActivated:id=>root.compare.assignPair(1,id)}
                }
            Row {
                id:toolbarActions;anchors.right:parent.right;anchors.rightMargin:10
                y:toolbar.stacked?selectors.height+16+(pairSelectors.visible?34:0):8;spacing:6
                QQC2.TextField {
                    QQC2.ContextMenu.menu: null
                    id:zoomInput;objectName:"compareZoomInput";width:Math.ceil(zoomMetrics.advanceWidth("1666.55"))+28;height:26;rightPadding:18;leftPadding:6
                    FontMetrics {id:zoomMetrics;font.family:Theme.monoFontFamily;font.pixelSize:Theme.fontSizeBody}
                    text:Number(canvas.zoomPercent.toFixed(2)).toString();selectByMouse:true;enabled:root.editable
                    color:Theme.textPrimary;font.family:Theme.monoFontFamily;font.pixelSize:Theme.fontSizeBody
                    validator:DoubleValidator {bottom:.0001;top:1000000;decimals:4;locale:"en_US";notation:DoubleValidator.StandardNotation}
                    background:Rectangle {radius:Theme.radiusMedium;color:Theme.bgInput;border.color:zoomInput.activeFocus?Theme.accent:Theme.borderDefault}
                    onTextEdited:{var value=Number(text);if(isFinite(value)&&value>0&&canvas.zoomPercent>0)canvas.zoomAt(value/canvas.zoomPercent,canvas.width/2,canvas.height/2)}
                    onEditingFinished:text=Qt.binding(function(){return Number(canvas.zoomPercent.toFixed(2)).toString()})
                    Text {anchors.right:parent.right;anchors.rightMargin:5;anchors.verticalCenter:parent.verticalCenter;text:"%";color:Theme.textMuted;font.pixelSize:11}
                }
                AppButton {objectName:"compareFit";text:qsTranslate("App","Fit");width:52;buttonHeight:26;enabled:root.editable;onClicked:canvas.fit("all")}
                AppButton {text:"100%";width:60;buttonHeight:26;enabled:root.editable;onClicked:canvas.actualPixels()}
                AppButton {objectName:"compareExportButton";variant:"primary";text:qsTranslate("App","Export");buttonHeight:26;enabled:root.editable&&root.compare.canExport&&(!root.exportVideo||root.compare.outPoint>root.compare.inPoint);onClicked:exportSettings.open()}
            }
        }
        Item {
            id: viewer
            anchors {left:parent.left;right:parent.right;top:toolbar.bottom;bottom:transport.top}
            clip:true
            CompareCanvas {id:canvas;objectName:"compareCanvas";anchors.fill:parent;controller:root.compare}
            MouseArea {
                id:navigation;objectName:"compareNavigation";anchors.fill:parent
                enabled:root.editable&&root.sources.length>0;acceptedButtons:Qt.LeftButton|Qt.MiddleButton|Qt.RightButton;hoverEnabled:true
                property bool movingDivider:false
                property bool moved:false
                property real startX:0;property real startY:0;property real previousX:0;property real previousY:0
                function nearDivider(x) {return root.opts.layout==="slider"&&Math.abs(x-canvas.contentRect.x-canvas.contentRect.width*root.opts.split)<12}
                function moveDivider(x) {if(canvas.contentRect.width>0)root.option("split",(x-canvas.contentRect.x)/canvas.contentRect.width)}
                cursorShape:movingDivider||nearDivider(mouseX)?Qt.SplitHCursor:pressed?Qt.ClosedHandCursor:root.opts.layout==="clicker"?Qt.PointingHandCursor:Qt.OpenHandCursor
                onPressed:mouse=>{
                    forceActiveFocus();movingDivider=mouse.button===Qt.LeftButton&&nearDivider(mouse.x);moved=false
                    startX=previousX=mouse.x;startY=previousY=mouse.y
                    if(!movingDivider&&root.opts.layout!=="clicker"){var id=canvas.sourceAt(mouse.x,mouse.y);if(id!=="")root.compare.selectSource(id)}
                }
                onPositionChanged:mouse=>{
                    if(!pressed || (pressedButtons===Qt.RightButton && root.opts.layout!=="clicker"))return
                    if(Math.hypot(mouse.x-startX,mouse.y-startY)>6)moved=true
                    if(movingDivider)moveDivider(mouse.x)
                    else if(moved)canvas.panBy(mouse.x-previousX,mouse.y-previousY,startX,startY)
                    previousX=mouse.x;previousY=mouse.y
                }
                onReleased:mouse=>{if(mouse.button===Qt.RightButton&&root.opts.layout!=="clicker"){root.openSourceMenu(canvas.sourceAt(mouse.x,mouse.y),navigation,mouse.x,mouse.y);return}if(root.opts.layout==="clicker"&&!moved){if(mouse.button===Qt.LeftButton)root.compare.cycleSource(1);else if(mouse.button===Qt.RightButton)root.compare.cycleSource(-1);}movingDivider=false}
                onCanceled:movingDivider=false
                onDoubleClicked:mouse=>{if(nearDivider(mouse.x))root.option("split",.5);else if(root.opts.layout!=="clicker")canvas.fit("all")}
                onWheel:wheel=>{canvas.zoomAt(wheel.angleDelta.y>0?1.12:1/1.12,wheel.x,wheel.y);wheel.accepted=true}
            }
            Rectangle {
                visible:root.opts.layout==="slider"&&root.sources.length>1
                x:canvas.contentRect.x+canvas.contentRect.width*root.opts.split-width/2
                y:canvas.contentRect.y;width:1.5;height:canvas.contentRect.height
                color:Theme.accent
            }
            DropArea {
                id:fileDrop;anchors.fill:parent
                onEntered:drag=>{if(!drag.hasUrls)drag.accepted=false}
                onDropped:drop=>{if(drop.hasUrls&&root.editable){root.compare.addSources(drop.urls);drop.acceptProposedAction()}}
            }
            Rectangle {anchors.fill:parent;visible:fileDrop.containsDrag;color:"#22F4A62A";border.color:Theme.accent;border.width:2}
            MouseArea {
                objectName:"compareEmptyPicker";anchors.fill:parent
                visible:root.sources.length===0;enabled:visible&&root.editable
                hoverEnabled:true;cursorShape:Qt.PointingHandCursor
                onClicked:files.open()
            }
            Column {
                anchors.centerIn:parent;spacing:14;width:Math.max(100,Math.min(640,parent.width-32));visible:root.sources.length===0
                AppIcon {anchors.horizontalCenter:parent.horizontalCenter;iconName:"compare";iconSize:44;color:Theme.textMuted}
                Text {objectName:"compareEmptyMessage";width:parent.width;text:qsTranslate("App","Drag and drop media to compare images and videos");horizontalAlignment:Text.AlignHCenter;wrapMode:Text.NoWrap;fontSizeMode:Text.HorizontalFit;minimumPixelSize:Theme.fontSizeSmall;color:Theme.textPrimary;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeTitle}
                AppButton {anchors.horizontalCenter:parent.horizontalCenter;text:qsTranslate("App","Add Media...");iconName:"add_file";variant:"secondary";enabled:root.editable;onClicked:files.open()}
            }
        }
        VideoTransportBar {
            id:transport;objectName:"compareTimeline"
            anchors {left:parent.left;right:parent.right;bottom:mediaList.top}
            visible:root.compare&&root.compare.hasVideo
            height:visible?implicitHeight:0
            enabled:root.editable
            frameRate:root.compare?root.compare.sourceFps:30
            player:comparePlayback
            audioOutput:root.compare&&root.opts.audioSource>=0?root.compare.audioOutput:null
        }
        Rectangle {
            id:mediaList
            anchors {left:parent.left;right:parent.right;bottom:parent.bottom}
            height:!root.listCollapsed?Math.min(root.listHeight,Math.max(180,mainArea.height*.45)):44
            visible:height>0;color:Theme.bgInput;border.color:Theme.borderSubtle;border.width:1
            Rectangle {anchors.top:parent.top;width:parent.width;height:1;color:Theme.borderSubtle}
            MouseArea {
                objectName:"compareListResize";z:20;anchors {left:parent.left;right:parent.right;top:parent.top} height:5;cursorShape:Qt.SizeVerCursor
                property real originY:0;property real initialHeight:0
                onPressed:mouse=>{originY=mapToItem(root,mouse.x,mouse.y).y;initialHeight=mediaList.height}
                onPositionChanged:mouse=>{if(pressed){root.listCollapsed=false;root.listHeight=Math.max(100,initialHeight+originY-mapToItem(root,mouse.x,mouse.y).y)}}
            }
            Rectangle {
                id: listHeader
                anchors {left:parent.left;right:parent.right;top:parent.top}
                height:44;color:Theme.bgSurface
                Row {
                    anchors.left:parent.left;anchors.leftMargin:16;y:10;spacing:10
                    AppIcon {iconName:"queue";iconSize:18;color:Theme.textPrimary;anchors.verticalCenter:parent.verticalCenter}
                    Text {anchors.verticalCenter:parent.verticalCenter;text:qsTranslate("App","Media");color:Theme.textPrimary;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSubtitle;font.weight:Font.DemiBold}
                    AppBadge {
                        anchors.verticalCenter:parent.verticalCenter
                        text:root.sources.length===1?qsTranslate("App","%n file","",root.sources.length):qsTranslate("App","%n files","",root.sources.length)
                        variant:root.sources.length>0?"accent":"neutral"
                    }
                }
                Row {
                    anchors.right:parent.right;anchors.rightMargin:12;y:8;spacing:4
                    AppIconButton {iconName:"add_file";buttonSize:28;tooltipText:qsTranslate("App","Add files");enabled:root.editable;onClicked:files.open()}
                    AppIconButton {iconName:"clear_all";buttonSize:28;tooltipText:qsTranslate("App","Clear sources");enabled:root.editable&&root.sources.length>0;onClicked:root.compare.clear()}
                    Rectangle {width:1;height:16;color:Theme.borderDefault;anchors.verticalCenter:parent.verticalCenter}
                    AppIconButton {iconName:root.listCollapsed?"chevron_up":"chevron_down";buttonSize:28;tooltipText:root.listCollapsed?qsTranslate("App","Expand queue"):qsTranslate("App","Collapse queue");onClicked:root.listCollapsed=!root.listCollapsed}
                }
                Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:1;color:Theme.borderSubtle}
            }
            Rectangle {
                id: columnHeader
                anchors {left:parent.left;right:parent.right;top:listHeader.bottom}
                height:root.listCollapsed?0:30
                visible:height>0;color:Theme.bgInputHover
                Text {x:12;width:28;height:parent.height;text:"#";horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;color:Theme.textSecondary}
                Text {x:84;height:parent.height;text:qsTranslate("App","Thumbnail / File");verticalAlignment:Text.AlignVCenter;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;color:Theme.textSecondary}
                Text {anchors.right:parent.right;anchors.rightMargin:56;width:zoomInput.width+96;height:parent.height;text:qsTranslate("App","Source scale %");horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;color:Theme.textSecondary}
                Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:1;color:Theme.borderSubtle}
            }
            Column {
                objectName:"compareEmptyQueue"
                anchors.centerIn:sourceList;width:Math.min(420,mediaList.width-40);spacing:8;z:1
                visible:!root.listCollapsed&&root.sources.length===0
                AppIcon {iconName:"inbox_import";iconSize:26;color:Theme.textMuted;anchors.horizontalCenter:parent.horizontalCenter}
                Text {
                    width:parent.width;text:qsTranslate("App","You media is empty.")
                    horizontalAlignment:Text.AlignHCenter;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeLabel;color:Theme.textPrimary
                }
                Text {
                    width:parent.width;text:qsTranslate("App","Add files or drop media into the preview.")
                    horizontalAlignment:Text.AlignHCenter;wrapMode:Text.WordWrap;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;color:Theme.textSecondary
                }
            }
            ListView {
                id:sourceList;objectName:"compareSourceList"
                anchors {left:parent.left;right:parent.right;top:columnHeader.bottom;bottom:parent.bottom}
                clip:true;visible:!root.listCollapsed;spacing:0;orientation:ListView.Vertical
                boundsBehavior:Flickable.StopAtBounds;reuseItems:true;cacheBuffer:112;model:root.compare?root.compare.sourceModel:null
                QQC2.ScrollBar.vertical:QQC2.ScrollBar {width:8;policy:QQC2.ScrollBar.AsNeeded}
                Keys.onPressed:event=>{
                    if(event.key!==Qt.Key_Up&&event.key!==Qt.Key_Down)return
                    var current=root.indexForId(root.compare.selectedId);var next=Math.max(0,Math.min(count-1,current+(event.key===Qt.Key_Up?-1:1)))
                    if(event.modifiers&Qt.AltModifier)root.compare.moveSource(current,next)
                    else if(next>=0)root.compare.selectSource(root.sources[next].id)
                    positionViewAtIndex(next,ListView.Contain);event.accepted=true
                }
                Connections {
                    target:root.compare
                    function onSourcesChanged(){if(!root.draggingRow){var i=root.indexForId(root.compare.selectedId);if(i>=0){sourceList.currentIndex=i;sourceList.positionViewAtIndex(i,ListView.Contain)}}}
                }
                Timer {
                    interval:40;repeat:true;running:root.draggingRow
                    onTriggered:{var delta=root.dragListY<28?-12:root.dragListY>sourceList.height-28?12:0;if(delta){sourceList.contentY=Math.max(0,Math.min(Math.max(0,sourceList.contentHeight-sourceList.height),sourceList.contentY+delta));root.updateDrop()}}
                }
                delegate:Rectangle {
                    id:sourceRow
                    required property int index
                    required property var sourceData
                    objectName:"compare-source-"+index;width:sourceList.width;height:84
                    function changeScale(value) {if(root.compare.selectedId!==sourceData.id)root.compare.selectSource(sourceData.id);root.compare.setSourceScale(sourceData.id,value)}
                    color:sourceData.selected?Theme.bgSelected:rowMouse.containsMouse?Theme.bgInputHover:index%2?Qt.darker(Theme.bgInput,1.08):Theme.bgInput
                    opacity:root.draggingRow&&root.draggedId===sourceData.id ? 0.55 : 1
                    Rectangle {anchors {left:parent.left;top:parent.top;bottom:parent.bottom} width:3;color:Theme.accent;visible:sourceRow.sourceData.selected}
                    MouseArea {
                        id:rowMouse;acceptedButtons:Qt.LeftButton|Qt.RightButton;objectName:"compare-drag-"+sourceRow.index;anchors.fill:parent;enabled:root.editable;hoverEnabled:true
                        property real startX:0;property real startY:0
                        onPressed:mouse=>{sourceList.forceActiveFocus();if(mouse.button===Qt.RightButton)return;startX=mouse.x;startY=mouse.y;root.draggedId=sourceRow.sourceData.id;root.compare.selectSource(root.draggedId)}
                        onPositionChanged:mouse=>{if(!pressed || pressedButtons!==Qt.LeftButton)return;if(Math.hypot(mouse.x-startX,mouse.y-startY)>8)root.draggingRow=true;if(root.draggingRow){root.dragListY=mapToItem(sourceList,mouse.x,mouse.y).y;root.updateDrop()}}
                        onReleased:mouse=>{if(mouse.button===Qt.RightButton){root.openSourceMenu(sourceRow.sourceData.id,rowMouse,mouse.x,mouse.y);return}var from=root.indexForId(root.draggedId);var to=root.dropIndex;var move=root.draggingRow&&from>=0&&to>=0;root.draggingRow=false;root.draggedId="";root.dropIndex=-1;if(move)Qt.callLater(root.compare.moveSource,from,to)}
                        onCanceled:{root.draggingRow=false;root.draggedId="";root.dropIndex=-1}
                    }
                    Rectangle {anchors.top:parent.top;width:parent.width;height:2;color:Theme.accent;visible:root.draggingRow&&root.dropIndex===sourceRow.index}
                    Text {x:12;width:28;height:parent.height;text:sourceRow.index+1;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;font.family:Theme.monoFontFamily;font.pixelSize:Theme.fontSizeBody;color:sourceRow.sourceData.selected?Theme.textPrimary:Theme.textMuted}
                    AppCheckBox {x:48;anchors.verticalCenter:parent.verticalCenter;width:24;height:28;label:"";checked:sourceRow.sourceData.visible;enabled:root.editable;onToggled:value=>root.compare.setSourceVisible(sourceRow.sourceData.id,value)}
                    Rectangle {
                        id:fileThumbnail;x:84;anchors.verticalCenter:parent.verticalCenter
                        width:mediaList.width>=1000?90:76;height:54;radius:Theme.radiusSmall
                        color:Theme.bgBase;border.color:Theme.borderSubtle;border.width:1;clip:true
                        CompareCanvas {anchors.fill:parent;anchors.margins:1;controller:root.compare;sourceId:sourceRow.sourceData.id}
                    }
                    Column {
                        x:fileThumbnail.x+fileThumbnail.width+12;anchors.verticalCenter:parent.verticalCenter;width:Math.max(10,scaleControls.x-x-12);spacing:6
                        Text {width:parent.width;text:sourceRow.sourceData.label+" · "+sourceRow.sourceData.name;color:Theme.textPrimary;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeLabel;font.weight:Font.Medium;elide:Text.ElideMiddle}
                        Text {width:parent.width;text:sourceRow.sourceData.missing?qsTranslate("App","Missing source"):sourceRow.sourceData.dimensions;color:sourceRow.sourceData.missing?Theme.warning:Theme.textSecondary;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;elide:Text.ElideRight}
                    }
                    Row {
                        id:scaleControls;anchors {right:removeButton.left;rightMargin:8;verticalCenter:parent.verticalCenter} spacing:4
                        AppIconButton {objectName:"compare-scale-reset-"+sourceRow.index;buttonSize:28;iconName:"reset";tooltipText:qsTranslate("App","Reset scale to 100%");enabled:root.editable;onClicked:sourceRow.changeScale(100)}
                        AppIconButton {objectName:"compare-scale-down-"+sourceRow.index;buttonSize:28;iconName:"minus";tooltipText:qsTranslate("App","Decrease scale");autoRepeat:true;enabled:root.editable;onClicked:sourceRow.changeScale(Math.max(.01,sourceRow.sourceData.scale-1))}
                        QQC2.TextField {
                            QQC2.ContextMenu.menu: null
                            id:scaleInput;objectName:"compare-scale-"+sourceRow.index;width:zoomInput.width;height:28;rightPadding:18;leftPadding:6
                            readonly property string canonical:Number(Number(sourceRow.sourceData.scale).toFixed(2)).toString()
                            text:canonical;enabled:root.editable;selectByMouse:true;horizontalAlignment:TextInput.AlignLeft
                            color:Theme.textPrimary;font.family:Theme.monoFontFamily;font.pixelSize:Theme.fontSizeBody
                            validator:DoubleValidator {bottom:.01;top:1000000;decimals:2;locale:"en_US";notation:DoubleValidator.StandardNotation}
                            background:Rectangle {radius:Theme.radiusMedium;color:Theme.bgInput;border.color:scaleInput.activeFocus?Theme.accent:Theme.borderDefault}
                            onEditingFinished:{var value=Number(text);if(isFinite(value)&&value>=.01)sourceRow.changeScale(value);text=Qt.binding(function(){return scaleInput.canonical})}
                            Text {anchors {right:parent.right;rightMargin:5;verticalCenter:parent.verticalCenter} text:"%";color:Theme.textMuted;font.pixelSize:10}
                        }
                        AppIconButton {objectName:"compare-scale-up-"+sourceRow.index;buttonSize:28;iconName:"plus";tooltipText:qsTranslate("App","Increase scale");autoRepeat:true;enabled:root.editable;onClicked:sourceRow.changeScale(Math.min(1000000,sourceRow.sourceData.scale+1))}
                    }
                    AppIconButton {id:removeButton;anchors {right:parent.right;rightMargin:12;verticalCenter:parent.verticalCenter} buttonSize:28;iconName:"trash";tooltipText:qsTranslate("App","Remove source");enabled:root.editable;onClicked:root.compare.removeSource(sourceRow.index)}
                    Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:1;color:Theme.borderSubtle}
                }
            }
        }
        Rectangle {
            anchors {left:parent.left;right:parent.right;bottom:parent.bottom} height:42
            visible:root.compare&&(root.compare.loading||root.compare.busy);color:Theme.bgSurface
            Text {anchors {left:parent.left;leftMargin:12;verticalCenter:parent.verticalCenter} text:root.compare?(root.compare.loading?qsTranslate("App","Loading…")+" "+root.compare.importDone+" / "+root.compare.importTotal:qsTranslate("App","Exporting…")+" "+Math.round(root.compare.progress*100)+"%"):"";color:Theme.textSecondary;font.family:Theme.fontFamily;font.pixelSize:12}
            AppButton {anchors {right:parent.right;rightMargin:8;verticalCenter:parent.verticalCenter} text:qsTranslate("App","Cancel");buttonHeight:28;onClicked:{if(root.compare.loading)root.compare.cancelImport();else root.compare.cancelExport()}}
        }
    }
    QQC2.Dialog {
        id:exportSettings;objectName:"compareExportDialog"
        closePolicy:QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
        property string errorMessage:""
        onOpened:errorMessage=""
        parent:QQC2.Overlay.overlay;anchors.centerIn:parent
        width:Math.min(480,parent?parent.width-32:480)
        height:Math.min(parent?parent.height-32:600,settingsColumn.implicitHeight+122)
        modal:true;focus:true;title:qsTranslate("App","Export Settings")
        header:Rectangle {
            height:44;color:Theme.bgSurface;border.width:1;border.color:Theme.borderDefault
            Text {anchors.left:parent.left;anchors.leftMargin:12;anchors.verticalCenter:parent.verticalCenter;text:exportSettings.title;color:Theme.textPrimary;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSubtitle;font.weight:Font.DemiBold}
            Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:1;color:Theme.borderSubtle}
        }
        background:Rectangle {color:Theme.bgSurface;radius:0;border.width:1;border.color:Theme.borderDefault}
        contentItem:InspectorScrollArea {
            clip:true;contentWidth:width;contentHeight:settingsColumn.implicitHeight
            Column {
                id:settingsColumn;width:parent.width;spacing:12
                ExportSettingsControls {width:parent.width;appBridge:exportBridge;enabled:root.editable}
                AppSegmentedControl {
                    objectName:"compareExportPath";width:parent.width;label:qsTranslate("App","Export Path")
                    model:[{label:qsTranslate("App","Same as Input"),value:"input"},{label:qsTranslate("App","Output"),value:"output"},{label:qsTranslate("App","Select Folder"),value:"folder"}]
                    currentValue:root.opts.destinationMode||"output";onActivated:value=>root.option("destinationMode",value)
                }
                Column {
                    width:parent.width;spacing:6;visible:root.opts.destinationMode==="folder"
                    AppButton {text:qsTranslate("App","Choose Folder...");iconName:"browse_folder";onClicked:compareExportFolder.open()}
                    Text {width:parent.width;text:root.opts.exportFolder?decodeURIComponent(root.opts.exportFolder.replace(/^file:\/\/\//,"")):qsTranslate("App","No folder selected");elide:Text.ElideMiddle;color:Theme.textSecondary;font.pixelSize:Theme.fontSizeLabel}
                }
                AppSegmentedControl {
                    objectName:"compareRenameMode";width:parent.width;label:qsTranslate("App","Rename Mode")
                    model:root.appBridge?root.appBridge.renameModeChoices:[];currentValue:root.opts.renameMode||"Auto";onActivated:value=>root.option("renameMode",value)
                }
                AppTextField {objectName:"compareCustomSuffix";width:parent.width;visible:root.opts.renameMode==="Custom";label:qsTranslate("App","Custom Suffix");text:root.opts.customSuffix||"";onTextEdited:value=>root.option("customSuffix",value)}
                Text {width:parent.width;visible:exportSettings.errorMessage!=="";text:exportSettings.errorMessage;wrapMode:Text.WordWrap;color:Theme.danger;font.pixelSize:Theme.fontSizeLabel}

                Rectangle {width:parent.width;height:1;color:Theme.borderSubtle}
                Text {text:qsTranslate("App","Include in export");color:Theme.textPrimary;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSubtitle}
                AppCheckBox {width:parent.width;label:qsTranslate("App","Heatmap legend");visible:root.opts.layout==="difference";checked:root.opts.captureLegend===true;onToggled:value=>root.option("captureLegend",value)}
                AppCheckBox {width:parent.width;label:qsTranslate("App","Comparison line");visible:root.opts.layout==="slider";checked:root.opts.captureDivider===true;onToggled:value=>root.option("captureDivider",value)}
                AppCheckBox {width:parent.width;label:qsTranslate("App","Source letters");checked:root.opts.captureLetter===true;onToggled:value=>root.option("captureLetter",value)}
                AppCheckBox {width:parent.width;label:qsTranslate("App","Filenames");checked:root.opts.captureName===true;onToggled:value=>root.option("captureName",value)}
                AppCheckBox {width:parent.width;label:qsTranslate("App","Resolutions");checked:root.opts.captureResolution===true;onToggled:value=>root.option("captureResolution",value)}
            }
        }
        footer:Item {
            height:50
            Row {
                anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;spacing:8
                AppButton {text:qsTranslate("App","Cancel");buttonHeight:30;onClicked:exportSettings.close()}
                AppButton {text:root.exportVideo?qsTranslate("App","Export Video"):qsTranslate("App","Save Image");variant:"primary";buttonHeight:30;enabled:root.editable&&root.compare.canExport;onClicked:root.openExport(root.exportVideo)}
            }
        }
    }
}
