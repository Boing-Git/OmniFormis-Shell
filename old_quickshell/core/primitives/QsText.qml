import QtQuick
import "../../theme"

Text {
    property int setWeight: 400
    property int setGrade: 0
    property int setRound: 0

    renderType: Text.QtRendering
    antialiasing: true
    font.hintingPreference: Font.PreferNoHinting
    font.family: Vars.fontFamily
    font.italic: Vars.fontItalic
    
    font.weight: Vars.fontBaselineEnabled ? Math.max(100, Math.min(1000, Vars.fontWeight + (setWeight - 400))) : setWeight
    
    font.variableAxes: Vars.fontBaselineEnabled ? {
        "ROND": Math.max(0, Math.min(100, Vars.fontRounding + setRound)),
        "GRAD": Math.max(-200, Math.min(150, Vars.fontGrading + setGrade))
    } : {
        "ROND": setRound,
        "GRAD": setGrade
    }
}
