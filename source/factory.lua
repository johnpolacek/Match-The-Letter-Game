module(..., package.seeall)

function newLetterButton(letter, isLowerCase, color)
	local background = display.newImage("images/buttons/"..color..".png")
	local letterGraphic
	if isLowerCase then
		letterGraphic = display.newImage("images/letters/lc/"..letter..".png")
	else
		letterGraphic = display.newImage("images/letters/uc/"..letter..".png")
	end
	local letterButton = {}
	letterButton.graphics = display.newGroup()
	letterButton.graphics:insert(background)
	letterButton.graphics:insert(letterGraphic)
	letterButton.letter = letter
	return letterButton	
end

function getRandomOrder(amount)
	local order ={}
	local i
	local temp
	local temp1
	for n = 1,amount do
		order[n] = n
	end
	for i=0,9 do
		for temp = 1,amount do
			n = math.random(1, amount)
			temp1 = order[temp]
			order[temp] = order[n]
			order[n] = temp1
		end
	end
	return order
end 

function getRandomLetters(numLetters, excludeLetter)
	local alphabet = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
	
	-- remove excluded letter
	local excludeIndex
	for i=1,#alphabet do
		if alphabet[i] == excludeLetter then
			excludeIndex = i
			alphabet[i] = nil
		end
	end
	table.remove(alphabet, excludeIndex)
	
	-- shuffle alphabet
	local randomLetterOrder = getRandomOrder(#alphabet)
	
	-- put selected letters into array
	local letters = {}
	for i=0,numLetters do
		letters[i] = alphabet[randomLetterOrder[i]]
	end
	
	return letters
end

function getRandomColors(numColors)
	local colors = {"blue","green","orange","purple","red","yellow"}
	local randomColorOrder = getRandomOrder(#colors)
	local randomColors = {}
	for i=1,numColors do
		randomColors[i] = colors[randomColorOrder[i]]
	end
	return randomColors
end