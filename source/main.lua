-- Version: 1.0
-- 

------------------------------------------------------------
-- Vars

local defaultWidth = 1024
local defaultHeight = 768
local displayWidth = display.viewableContentWidth
local displayHeight = display.viewableContentHeight
local yMargin = 20
local centerX = defaultWidth/2;
local centerY = defaultHeight/2;
local xAdjust = (defaultWidth - display.viewableContentWidth)/2
local yAdjust = (defaultHeight - display.viewableContentHeight)/2
local difficulty = 2  --default difficulty
local difficultySlider
local difficultySlots
local difficultyButton
local playButton
local letterButtons
local correctButton
local isLowerCase
local wrongGraphic
local playOrder
local currQuestion = 0
local oldScreen
local newScreen
local wordGraphic
local transitionDuration = 1000
local content = require("content")
local easing = require("easing")
local factory = require("factory")
local homeEnabled = true
local playEnabled = true


------------------------------------------------------------
-- Game Play


function launch()
	display.setStatusBar(display.HiddenStatusBar)
	
	-- create launch screen
	addLaunchScreen()
	
	newScreen = launchScreen
	
	-- assign random order for words
	playOrder = factory.getRandomOrder(#content)
end

function addLaunchScreen()
	launchScreen = display.newGroup()
	launchScreen.x = centerX
	launchScreen.y = centerY
	
	-- add background
	local background = display.newImageRect("images/graphics/background.jpg", 1024, 768, true)
	launchScreen:insert(background)
	
	-- add title
	local title = display.newImageRect("images/graphics/title.png", 774, 252, true)
	launchScreen:insert(title)
	title.y = -displayHeight/2 + title.height/2 + yMargin
	
	-- add copyright
	local copyright = display.newImageRect("images/graphics/copyright.png", 380, 34, true)
	copyright.y = displayHeight/2 - copyright.height/2
	launchScreen:insert(copyright)
	
	-- add the play button
	playButton = display.newImageRect("images/buttons/play.png", 234, 129)
	playButton.y = copyright.y - playButton.height/2 - copyright.height
	playButton:addEventListener("touch", onPlayTouch)
	launchScreen:insert(playButton)
	
	-- add difficulty slider
	addDifficultySlider()
	
	-- adjust spacing
	if yAdjust == 0 then
		title.y = title.y + yMargin*2
		playButton.y = playButton.y - yMargin
	elseif yAdjust > 50 then
		title.xScale = .8
		title.yScale = .8
		playButton.xScale = .7
		playButton.yScale = .7
		title.y = title.y - yMargin
		playButton.y = playButton.y + yMargin
		difficultySlider.y = difficultySlider.y - yMargin
		difficultyButton.y = difficultyButton.y - yMargin
	end
end

function addDifficultySlider()
	difficultySlider = display.newImageRect("images/graphics/difficulty.png", 548, 175)
	difficultySlider.x = centerX
	difficultySlider.y = centerY + difficultySlider.height/3
	difficultySlider:addEventListener("touch", onDifficultyTouch)
	
	-- add difficulty button
	difficultyButton = display.newImageRect("images/buttons/yellowcircle.png", 69, 69)
	difficultyButton:addEventListener("touch", onDifficultyDrag)
	
	-- define slots for difficulty slider
	difficultySlots = {centerX - difficultySlider.width/2 + difficultyButton.width/3.5, 
					   centerX - difficultySlider.width/4 + difficultyButton.width/7, 
					   centerX, 
					   centerX + difficultySlider.width/4 - difficultyButton.width/7, 
					   centerX + difficultySlider.width/2 - difficultyButton.width/3.5}
	
	-- set position
	difficultyButton.x = difficultySlots[difficulty]
	difficultyButton.y = difficultySlider.y
end

function setDifficulty(xPosition)
	difficulty = #difficultySlots
	for i=#difficultySlots, 2, -1 do
	   local middleX = (difficultySlots[i] + difficultySlots[i-1])/2
	   if xPosition < middleX then
	   		difficulty = i-1
	   end
	end
	transition.to(difficultyButton, {time=500, x=difficultySlots[difficulty], transition = easing.outExpo})
end

function addHomeButton()
	homeEnabled = true
	homeButton = display.newImage("images/buttons/home.png")
	homeButton.alpha = .9
	homeButton.y = yAdjust + homeButton.height/2
	homeButton:addEventListener("touch", onHomeTouch)
end

function showWord()
	-- get word from content data object
	local word = content[playOrder[currQuestion]].word
	
	-- make word graphic and transition in
	wordGraphic = display.newGroup()
	local wordColor = factory.getRandomColors(1)[1]
	local animationDelay = 500
	for i=1,string.len(word) do
		local char = word:sub(i,i)
		if char == " " then
			-- space
		else
			local char = factory.newLetterButton(char,isLowerCase,wordColor).graphics
			wordGraphic:insert(char)
			char.x = (char.width * .72) * (i-1)
			local charDelay = (i-1) * animationDelay
			timer.performWithDelay(charDelay, playLetterSound)
			transition.from(char, {time = 400, delay = charDelay, y=centerY+char.height, transition=easing.easeOutElastic})
		end
	end
	wordGraphic.x = centerX - wordGraphic.width/2
	wordGraphic.y = centerY - wordGraphic.height/2
	timer.performWithDelay(wordGraphic.numChildren * animationDelay + 1000, onWordComplete)
end

function nextQuestion()
	-- update screen var
	oldScreen = newScreen
	
	-- update question number index
	currQuestion = currQuestion+1
	if currQuestion > #playOrder then
		currQuestion = 1
	end
	local questionNumber = playOrder[currQuestion]
	print("Question# "..currQuestion)
	print("id "..content[questionNumber].id)
	
	-- add new image
	newScreen = display.newImageRect("images/pics/"..content[questionNumber].id..".jpg",1024, 768, true)
	newScreen.x = centerX
	newScreen.y = centerY
	
	-- do transitions
	transitionIn(newScreen)
	transitionOut(oldScreen)
	
	-- bring home button to front
	homeButton:toFront()
	
	-- make buttons
	letterButtons = {}
	local buttonColors = factory.getRandomColors(difficulty)
	
	-- determine upper or lower case
	isLowerCase = math.random(1,2) == 1
	
	-- make letter button for correct letter
	local letter = content[questionNumber].word:sub(1,1)
	table.insert(letterButtons, factory.newLetterButton(letter, isLowerCase, buttonColors[1]))
	correctButton = letterButtons[1].graphics
	local buttonWidth = correctButton.width
	
	-- make other letter buttons
	local letters = factory.getRandomLetters(difficulty-1, letter)
	for i=1, difficulty-1 do
		table.insert(letterButtons, factory.newLetterButton(letters[i], isLowerCase, buttonColors[i+1]))
	end
	
	-- position letter buttons and add touch event listener
	local randomLetterOrder = factory.getRandomOrder(#letterButtons)
	local buttonSpacing = buttonWidth * 1.25
	local buttonsWidth = (#letterButtons * buttonWidth) + ((#letterButtons-1) * (buttonSpacing/4))
	local buttonsX = centerX - (buttonsWidth/2) + 10
	for i=1, #letterButtons do
		local button = letterButtons[i].graphics
		button.y = defaultHeight - button.height - yAdjust
		button.x = buttonsX + (buttonSpacing * (randomLetterOrder[i]-1))
		button:addEventListener("touch", onLetterTouch)
		local randomDelay = transitionDuration + (math.random(1,10) * 10)
		transition.from(button, {time = 500, delay = randomDelay, y = defaultHeight + button.height, transition=easing.easeOutElastic})
	end
	
	-- play bubbles sound when letters animate in
	timer.performWithDelay(transitionDuration, playBubbles)
	
	-- enable home button
	homeEnabled = true
end

function clearQuestion()
	-- remove wrongGraphic if present
	if wrongGraphic then
		wrongGraphic:removeSelf()
		wrongGraphic = nil
	end
	
	-- remove all letter buttons
	for i=1,#letterButtons do
		letterButtons[i].graphics:removeSelf()
		letterButtons[i].graphics = nil
	end
end

function goHome()
	-- update screen var
	oldScreen = newScreen
	
	addLaunchScreen()
	newScreen = launchScreen
	
	-- do transitions
	transitionIn(newScreen)
	transitionIn(difficultySlider)
	transitionIn(difficultyButton)
	transitionOut(oldScreen)
	transitionOut(homeButton)
	
	for i=1,#letterButtons do
		transitionOut(letterButtons[i].graphics)
	end
	
	-- enable play button
	playEnabled = true
end

------------------------------------------------------------
-- SOUNDS

function playLetterSound()
	media.playSound("audio/letter.mp3")
end

function playBubbles()
	media.playSound("audio/bubbles.mp3")
end

function playWord()
	local audioFile = "audio/words/"..content[playOrder[currQuestion]].id..".mp3"
	media.playSound(audioFile, showWord)
end


------------------------------------------------------------
-- TRANSITIONS

function transitionIn(target)
	transition.from(target, {time = transitionDuration, x = defaultWidth + centerX, transition=easing.inOutExpo})
end

function transitionOut(target)
	transition.to(target, {time = transitionDuration, x = -centerX, transition=easing.inOutExpo, onComplete = onTransitionOutComplete})
end

function onTransitionOutComplete(target)
	target:removeSelf()
	target = nil
end


------------------------------------------------------------
-- EVENTS

function onDifficultyDrag(event)
	local t = event.target

	local phase = event.phase
	if "began" == phase then
		-- Spurious events can be sent to the target, e.g. the user presses 
		-- elsewhere on the screen and then moves the finger over the target.
		-- To prevent this, we add this flag. Only when it's true will "move"
		-- events be sent to the target.
		t.isFocus = true

		-- Store initial position
		t.x0 = event.x - t.x
	elseif t.isFocus then
		if "moved" == phase then
			-- Make object move (we subtract t.x0,t.y0 so that moves are
			-- relative to initial grab point, rather than object "snapping").
			local newX = event.x - t.x0
			if newX > difficultySlots[1] and newX < difficultySlots[#difficultySlots] then
				t.x = newX
			elseif newX < difficultySlots[1] then
				t.x = difficultySlots[1]
			elseif newX > difficultySlots[#difficultySlots] then
				t.x = difficultySlots[#difficultySlots]
			end
		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false
			setDifficulty(t.x)
		end
	end

	-- Important to return true. This tells the system that the event
	-- should not be propagated to listeners of any objects underneath.
	return true
end

function onDifficultyTouch(event)
	if "ended" == event.phase then
		setDifficulty(event.x)
	end
end

function onPlayTouch(event)
	if "ended" == event.phase and playEnabled == true then
		-- disable play button touches
		playEnabled = false
		
		-- add home button
		addHomeButton()
		
		-- do transitions
		transitionIn(homeButton)
		transitionOut(playButton)
		transitionOut(difficultySlider)
		transitionOut(difficultyButton)
		nextQuestion()
	end
end

function onLetterTouch(event)
	local t = event.target
	if "ended" == event.phase then
		if t == correctButton then
			onCorrect()
		else
			onIncorrect(t)
		end
		
	end
end

function onIncorrect(incorrectButton)
	media.playSound("audio/wrong.mp3")
	wrongGraphic = display.newImageRect("images/graphics/wrong.png", 137, 136)
	wrongGraphic.x = incorrectButton.x + incorrectButton.width/2
	wrongGraphic.y = incorrectButton.y + incorrectButton.height/2
	transition.to(incorrectButton, {time=100, delay=500, alpha=0})
	transition.to(wrongGraphic, {time=200, delay=500, alpha=0, onComplete=wrongCompleteListener})
	local wrongCompleteListener = function(obj)
       obj:removeSelf()
       obj = nil
       incorrectButton:removeSelf()
       incorrectButton = nil
	end
end

function onCorrect()
	-- play correct sound then display word
	media.playSound("audio/correct.mp3", playWord)
	
	-- remove the letter buttons
	clearQuestion()
	
	-- disable the home button until new screen is shown
	homeEnabled = false
end

function onWordComplete(event)
	transition.to(wordGraphic, {time = transitionDuration, x = -defaultWidth, transition=easing.inOutExpo, onComplete = onTransitionOutComplete})
	nextQuestion()
end

function onHomeTouch(event)
	if "ended" == event.phase and homeEnabled == true then
		-- disable home button to prevent double touches
		homeEnabled = false
		goHome()
	end
end


------------------------------------------------------------
-- Start app

launch()
