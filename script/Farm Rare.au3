;function: farmRare
;-Automatically farms rares in story mode
;pre:
;   -config must be set for script
;   -required config keys: map, capture, guardian-dungeon
;author: GkevinOD
Func farmRare()
    ;beginning script
    setLog("~~~Starting 'Farm Rare' script~~~")
    setLog("*Loading config for Farm Rare.")

    ;getting configs
    Dim $map = "map-" & StringReplace(IniRead(@ScriptDir & "/config.ini", "Farm Rare", "map", "phantom forest"), " ", "-")
    Dim $guardian = IniRead(@ScriptDir & "/config.ini", "Farm Rare", "guardian-dungeon", "0")
    Dim $difficulty = IniRead(@ScriptDir & "/config.ini", "Farm Rare", "difficulty", "normal")
    Dim $captures[0];

    Dim $rawCapture = StringSplit(IniRead(@ScriptDir & "/config.ini", "Farm Rare", "capture", "legendary,super rare,rare,exotic"), ",", 2)
    For $capture In $rawCapture
        Local $grade = StringReplace($capture, " ", "-")
        If FileExists(@ScriptDir & "/core/images/catch/catch-" & $grade & ".bmp") Then
            _ArrayAdd($captures, "catch-" & $grade)

            Local $tempInt = 2
            While FileExists(@ScriptDir & "/core/images/catch/catch-" & $grade & $tempInt & ".bmp")
                _ArrayAdd($captures, "catch-" & $grade & $tempInt)
                $tempInt += 1
            WEnd
        EndIf
    Next

    ;setting up data capture
    GUICtrlSetData($cmbLoad, "Select a script..")

    Local $dataRuns = 0
    Local $dataGuardians = 0
    Local $dataEncounter = 0
    Local $dataStrCaught = ""

    While True
        While True
            GUICtrlSetData($listScript, "")
            GUICtrlSetData($listScript, "# of Runs: " & $dataRuns & "|# of Guardian Dungeons: " & $dataGuardians & "|# of Rare Encounters: " & $dataEncounter & "|Astromon Caught: " & StringMid($dataStrCaught, 2))

            If _Sleep(100) Then ExitLoop(2) ;to stop farming
            If checkLocations("map", "map-stage", "astroleague", "village", "manage", "monsters", "quests", "map-battle") = 1 Then
                setLog("Going into battle...", 1)
                If navigate("map") = 1 Then
                    If enterStage($map, $difficulty, True, True) = 0 Then
                        setLog("Error: Could not enter map stage.")
                        ExitLoop(2)
                    EndIf
                    $dataRuns += 1
                    setLog("Waiting for astromon.", 1)
                EndIf
            EndIf
            
            If checkLocations("battle-end-exp", "battle-sell") = 1 Then
                clickPointUntil($game_coorTap, "battle-end")
            EndIf
            
            If checkLocations("battle-end") = 1 Then
                clickPoint($game_coorTap, 5)
                If waitLocation("unknown", 10) = 0 Then
                    setLog("Autobattle finished.", 1)
                    If checkPixel($battle_pixelQuest) = True Then
                        setLog("Detected quest complete, navigating to village.", 1)
                        If navigate("village", "quests") = 1 Then
                            setLog("Collecting quests.", 1)
                            For $questTab In $village_coorArrayQuestsTab ;quest tabs
                                clickPoint(StringSplit($questTab, ",", 2))
                                While isArray(findImageWait("misc-quests-get-reward", 3, 100)) = True
                                    clickImage("misc-quests-get-reward", 100)
                                WEnd
                            Next
                        EndIf
                    EndIf
                    ExitLoop
                EndIf
                $dataRuns += 1
            EndIf
            
            If checkLocations("battle") = 1 Then
                If isArray(findImagesWait($imagesRareAstromon, 5, 100)) Then
                    $dataEncounter += 1
                    setLog("An astromon has been found!", 1)
                    If navigate("battle", "catch-mode") = 1 Then
                        Local $tempStr = catch($captures, True)
        
                        If Not $tempStr = "" Then $dataStrCaught &= ", " & $tempStr
                        setLog("Finish catching, attacking..", 1)
                        clickPoint($battle_coorAuto)
                    EndIf
                EndIf
            EndIf
            
            If checkLocations("map-gem-full", "battle-gem-full") = 1 Then
                setLog("Gem is full, going to sell gems...", 1)
                If navigate("village", "manage") = 1 Then
                    sellGems($imagesUnwantedGems)
                EndIf
            EndIf
            
            If checkLocations("lost-connection") = 1 Then
                clickPoint($game_coorConnectionRetry)
            EndIf
        WEnd

        Dim $foundDungeon = 0
        If $guardian = 1 And navigate("map", "guardian-dungeons") = 1 Then
            setLog("Checking for guardian dungeons...", 1)
            While checkLocations("guardian-dungeons") = 1
                If clickImageUntil("misc-dungeon-energy", "map-battle", 50) = 1 Then
                    clickPointWait($map_coorBattle, "map-battle", 5)
                    
                    If _Sleep(3000) Then ExitLoop(2)

                    If checkLocations("map-gem-full", "battle-gem-full") = 1 Then
                        setLog("Gem is full, going to sell gems...", 1)
                        If navigate("village", "manage") = 1 Then
                            sellGems($imagesUnwantedGems)
                        EndIf

                        clickImageUntil("misc-dungeon-energy", "map-battle", 50)
                        clickPointWait($map_coorBattle, "map-battle", 5)
                    EndIf
                    $foundDungeon += 1
                    setLogReplace("Found dungeon, attacking x" & $foundDungeon & ".")

                    If waitLocation("battle-end-exp", 240) = 0 Then
                        setLog("Unable to finish golem in 5 minutes!", 1)
                        ExitLoop
                    EndIf
                    
                    While checkLocations("battle-end") = 0
                        clickPoint($game_coorTap)
                    WEnd
                    
                    clickImageUntil("battle-exit", "guardian-dungeons")
                Else
                    setLog("Guardian dungeon not found, going back to map.", 1)
                    navigate("map")
                    ExitLoop
                EndIf
            WEnd
        EndIf
        $dataGuardians += $foundDungeon
    WEnd

    setLog("~~~Finished 'Farm Rare' script~~~")
EndFunc