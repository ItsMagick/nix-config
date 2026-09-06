import QtQuick
import QtQuick.Effects
import "../"

Item {
    id: root

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    readonly property color base: _theme.base
    readonly property color blue: _theme.blue
    readonly property color crust: _theme.crust
    readonly property color mantle: _theme.mantle
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color sapphire: _theme.sapphire
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color text: _theme.text

    MatugenColors {
        id: _theme
    }

    // Master Container
    Rectangle {
        id: windowContent

        property real accentBlend: 0.0

        // ---------------------------------------------------------------------
        // GLOBAL THEME & STATE CONTROLS
        // ---------------------------------------------------------------------

        // 5. Slow Color Temperature Drift (Fixed for Live Theme Reloading)
        property real baseBlend: 0.0

        // 3 separate breathing phases for organic offset
        property real breathA: (Math.sin(time * 3) + 1) / 2       // Glow phase
        property real breathB: (Math.sin(time * 3 + 0.6) + 1) / 2 // Core phase
        property real breathC: (Math.sin(time * 3 + 1.2) + 1) / 2 // Background phase

        // Animation States
        property real calmState: 0.0
        // Dynamically tints between blue and sapphire based on the live theme properties
        property color currentAccentLavender: Qt.tint(root.blue, Qt.rgba(root.sapphire.r, root.sapphire.g, root.sapphire.b, accentBlend))
        // Dynamically tints between mauve and pink based on the live theme properties
        property color currentBasePurple: Qt.tint(root.mauve, Qt.rgba(root.pink.r, root.pink.g, root.pink.b, baseBlend))
        property real globalOrbitAngle: 0
        property real popShockwave: 0.0

        // 9. Breathing Phase Offsets (Continuous Time Engine)
        property real time: 0

        anchors.fill: parent
        clip: true
        color: root.base

        // Window Entrance Animation
        opacity: 0.0
        radius: 12
        scale: 0.98

        SequentialAnimation on accentBlend {
            loops: Animation.Infinite
            running: true

            NumberAnimation {
                duration: 15000
                easing.type: Easing.InOutSine
                to: 1.0
            }
            NumberAnimation {
                duration: 15000
                easing.type: Easing.InOutSine
                to: 0.0
            }
        }
        SequentialAnimation on baseBlend {
            loops: Animation.Infinite
            running: true

            NumberAnimation {
                duration: 15000
                easing.type: Easing.InOutSine
                to: 1.0
            }
            NumberAnimation {
                duration: 15000
                easing.type: Easing.InOutSine
                to: 0.0
            }
        }
        NumberAnimation on globalOrbitAngle {
            duration: 60000
            from: 0
            loops: Animation.Infinite
            running: true
            to: Math.PI * 2
        }
        NumberAnimation on time {
            duration: 15000
            from: 0
            loops: Animation.Infinite
            running: true
            to: Math.PI * 2
        }

        Component.onCompleted: entranceAnimation.start()

        ParallelAnimation {
            id: entranceAnimation

            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
                property: "opacity"
                target: windowContent
                to: 1.0
            }
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
                property: "scale"
                target: windowContent
                to: 1.0
            }
        }

        // ---------------------------------------------------------------------
        // BACKGROUND ARTIFACTS
        // ---------------------------------------------------------------------

        // 1. Large Flowing Background Orb A
        Rectangle {
            id: backgroundOrbA

            antialiasing: true
            color: windowContent.currentBasePurple
            height: width
            layer.enabled: true

            // Offset breathing C
            opacity: 0.025 + (windowContent.breathC * 0.015 * (1.0 - (windowContent.calmState * 0.3)))
            radius: width / 2
            width: parent.width * 0.8

            // 1. Subtle Depth Parallax (Follows worldCenter drift slightly)
            // 6. Energy Density Shift After Calm (Reduced amplitude)
            x: (parent.width / 2 - width / 2) + Math.cos(windowContent.globalOrbitAngle * 2) * (250 - windowContent.calmState * 60) + (worldCenter.driftX * 0.4)
            y: (parent.height / 2 - height / 2) + Math.sin(windowContent.globalOrbitAngle * 2) * (150 - windowContent.calmState * 40) + (worldCenter.driftY * 0.4)

            layer.effect: MultiEffect {
                blur: 1.0
                blurEnabled: true
                blurMax: 64
            }
        }

        // 2. Large Flowing Background Orb B
        Rectangle {
            id: backgroundOrbB

            antialiasing: true
            color: windowContent.currentAccentLavender
            height: width
            layer.enabled: true
            opacity: 0.020 + (windowContent.breathC * 0.012 * (1.0 - (windowContent.calmState * 0.3)))
            radius: width / 2
            width: parent.width * 0.9
            x: (parent.width / 2 - width / 2) + Math.sin(windowContent.globalOrbitAngle * 1.5) * -(250 - windowContent.calmState * 60) + (worldCenter.driftX * 0.3)
            y: (parent.height / 2 - height / 2) + Math.cos(windowContent.globalOrbitAngle * 1.5) * -(150 - windowContent.calmState * 40) + (worldCenter.driftY * 0.3)

            layer.effect: MultiEffect {
                blur: 1.0
                blurEnabled: true
                blurMax: 80
            }
        }

        // 3. Gravitational Floating Particles (Improved Naturalism)
        Repeater {
            model: 20

            Rectangle {
                id: particle

                property real baseX: (index * 113) % root.width
                property real baseY: (index * 137) % root.height
                property real randomPhase: index * 0.47
                property real vecX: (root.width / 2) - baseX
                property real vecY: (root.height / 2) - baseY

                antialiasing: true
                color: index % 3 === 0 ? windowContent.currentAccentLavender : windowContent.currentBasePurple
                height: width
                layer.enabled: true
                opacity: ((index % 3) * 0.1 + 0.1) + (windowContent.popShockwave * 0.2)
                radius: width / 2
                width: (index % 4) + 3

                // 4. Improve Particle Naturalism (Elliptical drift instead of vertical bounce)
                // 1. Parallax addition
                x: baseX + Math.cos(windowContent.time * 4 + randomPhase) * 15 * windowContent.calmState + (worldCenter.driftX * 0.8) - (vecX * 0.04 * windowContent.popShockwave)
                y: baseY + Math.sin(windowContent.time * 3 + randomPhase) * 15 * windowContent.calmState + (worldCenter.driftY * 0.8) - (vecY * 0.04 * windowContent.popShockwave)

                layer.effect: MultiEffect {
                    blur: 1.0
                    blurEnabled: true
                    blurMax: (index % 3) * 3 + 2
                }
            }
        }

        // ---------------------------------------------------------------------
        // THE ASSISTANT CORE
        // ---------------------------------------------------------------------

        // Premium Glow Aura
        Item {
            id: orbGlow

            property real baseOpacity: 0.0
            property real baseScale: 0.8

            anchors.centerIn: parent
            height: 150

            // 9. Offset breathing A
            // 6. Energy Shift (Lowers glow mildly in calm state)
            opacity: baseOpacity * (1.0 - (windowContent.calmState * 0.2)) * (0.8 + (windowContent.breathA * 0.2))
            scale: baseScale + (windowContent.breathA * 0.03)
            width: 150

            Repeater {
                model: 2

                Rectangle {
                    anchors.centerIn: parent
                    antialiasing: true
                    color: windowContent.currentBasePurple
                    height: width
                    opacity: index === 0 ? 0.12 : 0.05
                    radius: width / 2
                    width: parent.width + (index * 40) + 20
                }
            }
        }

        // Redesigned Diffuse Shockwave Fade
        Rectangle {
            id: diffuseShockwave

            anchors.centerIn: parent
            antialiasing: true
            color: windowContent.currentAccentLavender
            height: 150
            opacity: windowContent.popShockwave * 0.12
            radius: width / 2
            scale: 1.0 + (windowContent.popShockwave * 0.8)
            width: 150
        }

        // Center Wrapper
        Item {
            id: worldCenter

            property real driftX: 0
            property real driftY: 0

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: driftX
            anchors.verticalCenterOffset: driftY
            height: 150

            // 10. Ultra-Subtle Idle Micro Drift
            rotation: windowContent.calmState * Math.sin(windowContent.time * 2) * 2.0
            width: 150

            SequentialAnimation on driftX {
                loops: Animation.Infinite

                NumberAnimation {
                    duration: 7450
                    easing.type: Easing.InOutSine
                    to: 2
                }
                NumberAnimation {
                    duration: 6920
                    easing.type: Easing.InOutSine
                    to: -1.5
                }
            }
            SequentialAnimation on driftY {
                loops: Animation.Infinite

                NumberAnimation {
                    duration: 8210
                    easing.type: Easing.InOutSine
                    to: 1.5
                }
                NumberAnimation {
                    duration: 7630
                    easing.type: Easing.InOutSine
                    to: -2
                }
            }

            Item {
                id: orb

                anchors.fill: parent

                // 1. Loading Shell
                Rectangle {
                    id: loadingShell

                    anchors.fill: parent
                    antialiasing: true
                    opacity: 1.0
                    radius: width / 2

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            color: root.surface2
                            position: 0.0
                        }
                        GradientStop {
                            color: root.surface0
                            position: 1.0
                        }
                    }
                }

                // 2. Activated Energy Core
                Item {
                    id: activeEnergyCore

                    anchors.fill: parent
                    opacity: 0.0

                    // 9. Offset breathing B
                    scale: 1.0 + (windowContent.breathB * 0.015)

                    // Layer A: Oscillating Base Gradient
                    Rectangle {
                        id: fluidGradientLayer

                        property real oscRotation: 0

                        anchors.fill: parent
                        antialiasing: true
                        radius: width / 2
                        rotation: oscRotation

                        gradient: Gradient {
                            orientation: Gradient.Horizontal

                            GradientStop {
                                color: windowContent.currentBasePurple
                                position: 0.0

                                SequentialAnimation on position {
                                    loops: Animation.Infinite

                                    NumberAnimation {
                                        duration: 5000
                                        easing.type: Easing.InOutSine
                                        to: 0.2
                                    }
                                    NumberAnimation {
                                        duration: 5000
                                        easing.type: Easing.InOutSine
                                        to: 0.0
                                    }
                                }
                            }
                            GradientStop {
                                color: windowContent.currentAccentLavender
                                position: 1.0

                                SequentialAnimation on position {
                                    loops: Animation.Infinite

                                    NumberAnimation {
                                        duration: 4500
                                        easing.type: Easing.InOutSine
                                        to: 0.8
                                    }
                                    NumberAnimation {
                                        duration: 4500
                                        easing.type: Easing.InOutSine
                                        to: 1.0
                                    }
                                }
                            }
                        }
                        SequentialAnimation on oscRotation {
                            loops: Animation.Infinite

                            NumberAnimation {
                                duration: 6000
                                easing.type: Easing.InOutSine
                                to: 15
                            }
                            NumberAnimation {
                                duration: 6000
                                easing.type: Easing.InOutSine
                                to: -15
                            }
                        }
                    }

                    // 2. Micro Inner Pulse to Core (Circulating core energy, not scaling)
                    Item {
                        anchors.fill: parent
                        opacity: 0.3 + (windowContent.breathB * 0.2)

                        Rectangle {
                            anchors.centerIn: parent
                            color: windowContent.currentAccentLavender
                            height: width
                            layer.enabled: true
                            opacity: 0.4
                            radius: width / 2
                            width: parent.width * 0.6

                            layer.effect: MultiEffect {
                                blur: 1.0
                                blurEnabled: true
                                blurMax: 32
                            }
                        }
                    }

                    // Layer B: Subtle transparent mask oscillating opposite
                    Rectangle {
                        property real maskRotation: 0

                        anchors.fill: parent
                        antialiasing: true
                        opacity: 0.8
                        radius: width / 2
                        rotation: maskRotation

                        gradient: Gradient {
                            orientation: Gradient.Vertical

                            GradientStop {
                                color: "transparent"
                                position: 0.0
                            }
                            GradientStop {
                                color: windowContent.currentAccentLavender
                                position: 0.4
                            }
                            GradientStop {
                                color: windowContent.currentAccentLavender
                                position: 0.6
                            }
                            GradientStop {
                                color: "transparent"
                                position: 1.0
                            }
                        }
                        SequentialAnimation on maskRotation {
                            loops: Animation.Infinite

                            NumberAnimation {
                                duration: 7000
                                easing.type: Easing.InOutSine
                                to: -20
                            }
                            NumberAnimation {
                                duration: 7000
                                easing.type: Easing.InOutSine
                                to: 20
                            }
                        }
                    }

                    // 7. Subtle Orb Surface Noise (Simulated via rotating organic low-opacity elements)
                    Item {
                        anchors.fill: parent
                        clip: true
                        layer.enabled: true
                        opacity: 0.03

                        layer.effect: MultiEffect {
                            blur: 1.0
                            blurEnabled: true
                            blurMax: 2
                        }

                        Repeater {
                            model: 24

                            Rectangle {
                                property real angle: index * 15
                                property real dist: (index * 4) % (parent.width / 2.2)

                                color: root.text
                                height: width
                                radius: width / 2
                                rotation: windowContent.time * 20 * (index % 2 === 0 ? 1 : -1)
                                width: (index % 3) + 2
                                x: (parent.width / 2) + Math.cos(angle) * dist - width / 2
                                y: (parent.height / 2) + Math.sin(angle) * dist - height / 2
                            }
                        }
                    }

                    // 4. Subtle Light Refraction Sweep
                    Rectangle {
                        id: refractionLayer

                        property real sweepPos: 0.0

                        anchors.fill: parent
                        antialiasing: true
                        color: "transparent"

                        // 6. Density Shift (Diminish refraction sweeps slightly on idle)
                        opacity: 1.0 - (windowContent.calmState * 0.2)
                        radius: width / 2
                        rotation: 25

                        gradient: Gradient {
                            orientation: Gradient.Horizontal

                            GradientStop {
                                color: "transparent"
                                position: Math.max(0.0, Math.min(1.0, refractionLayer.sweepPos - 0.2))
                            }
                            GradientStop {
                                color: Qt.alpha(root.text, 0.08)
                                position: Math.max(0.0, Math.min(1.0, refractionLayer.sweepPos))
                            }
                            GradientStop {
                                color: "transparent"
                                position: Math.max(0.0, Math.min(1.0, refractionLayer.sweepPos + 0.2))
                            }
                        }
                        SequentialAnimation on sweepPos {
                            loops: Animation.Infinite
                            running: true

                            NumberAnimation {
                                duration: 8000
                                easing.type: Easing.InOutSine
                                from: -0.5
                                to: 1.5
                            }
                            PauseAnimation {
                                duration: 4000
                            }
                        }
                    }

                    // 3. Soft Ambient Edge Lighting (Inner rim light via blurred border trick)
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1 // Keep inside bounds
                        antialiasing: true
                        border.color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.15 + windowContent.breathA * 0.1)
                        border.width: 1.5
                        color: "transparent"
                        layer.enabled: true
                        radius: width / 2

                        layer.effect: MultiEffect {
                            blur: 1.0
                            blurEnabled: true
                            blurMax: 4
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // MASTER CINEMATIC SEQUENCE
        // ---------------------------------------------------------------------
        SequentialAnimation {
            id: introSequence

            running: true

            PauseAnimation {
                duration: 200
            }

            // Phase 1: Loading Wind-Up
            NumberAnimation {
                duration: 1200
                easing.type: Easing.InCubic
                from: 0
                property: "rotation"
                target: loadingShell
                to: 360
            }

            // Phase 2: Anticipation Contraction
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutSine
                property: "scale"
                target: orb
                to: 0.96
            }
            PauseAnimation {
                duration: 100
            }

            // Phase 3: The Transformation Pop
            ParallelAnimation {
                NumberAnimation {
                    duration: 150
                    property: "opacity"
                    target: loadingShell
                    to: 0.0
                }
                NumberAnimation {
                    duration: 300
                    property: "opacity"
                    target: activeEnergyCore
                    to: 1.0
                }
                SequentialAnimation {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                        property: "scale"
                        target: orb
                        to: 1.05
                    }
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.InOutSine
                        property: "scale"
                        target: orb
                        to: 1.0
                    }
                }

                // 8. Refine Shockwave Dissipation (Asymmetrical decay: Fast rise, slow lingering fade)
                SequentialAnimation {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                        from: 0.0
                        property: "popShockwave"
                        target: windowContent
                        to: 1.0
                    }
                    NumberAnimation {
                        duration: 1200
                        easing.type: Easing.OutQuart
                        property: "popShockwave"
                        target: windowContent
                        to: 0.0
                    }
                }
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutSine
                    property: "baseOpacity"
                    target: orbGlow
                    to: 1.0
                }
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutBack
                    property: "baseScale"
                    target: orbGlow
                    to: 1.0
                }
            }

            // Phase 4: Settle into Calm Idle State
            NumberAnimation {
                duration: 2500
                easing.type: Easing.InOutSine
                from: 0.0
                property: "calmState"
                target: windowContent
                to: 1.0
            }
        }
    }
}
