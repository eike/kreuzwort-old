# Kreuzwort.coffee
#
# Copyright 2018 Eike Schulte
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Word
    constructor: (@cells, @direction) ->
        @callbacks =
            changed: [ ]
            completed: [ ]
            selected: [ ]
            unselected: [ ]
    
    addCallback: (event, callback) ->
        @callbacks[event].push(callback)
    
    trigger: (event, data) ->
        for callback in @callbacks[event]
            callback(data, this)
    
    toString: (emptySymbol = '␣') ->
        (for cell in @cells
            if cell.innerHTML == '&nbsp;'
                emptySymbol
            else
                cell.innerHTML).join ''
    
    addClass: (className = 'current-word') ->
        for cell in @cells
            cell.classList.add(className)
        return
    
    removeClass: (className = 'current-word') ->
        for cell in @cells
            cell.classList.remove(className)
        return

Object.defineProperties Word.prototype, 
    clue: 
        get: ->
            clue = @startingCell.getAttribute "data-clue-#{@direction}"
            if clue? and clue != "" then clue else undefined
        set: (clue) ->
            clue = '' unless clue?
            @startingCell.setAttribute "data-clue-#{@direction}", clue
    explanation: 
        get: ->
            explanation = @startingCell.getAttribute "data-explanation-#{@direction}"
            if explanation? and explanation != "" then explanation else undefined
        set: (explanation) ->
            @startingCell.setAttribute "data-explanation-#{@direction}", explanation
    explicitNumber:
        get: -> @startingCell.getAttribute 'data-explicit-number'
    firstEmptyPosition:
        get: ->
            for cell, index in @cells
                return index if cell.textContent == ' '
            return @length
    isComplete:
        get: ->
            for cell in @cells
                return false if cell.textContent == ' '
            return true
    isEmpty:
        get: ->
            for cell in @cells
                return false unless cell.textContent == ' '
            return true
    length:
        get: -> @cells.length
    number:
        get: -> @startingCell.getAttribute 'data-cell-number'
        set: (number) ->
            @startingCell.setAttribute "data-cell-number", number
    startingCell:
        get: -> @cells[0]

class Kreuzwort
    constructor: (@cells, @words, @saveId, @features = Kreuzwort.featuresFull, hiddenContainer = document.body) ->
        @callbacks =
            changed: [ @save.bind(this) ]
            input: [ standardInputCallback ]
            selectionChanged: [ ]

        #@previousInput = createSecretInput()
        #@previousInput.onfocus = () =>
        #    @retrogressCursor()
        #    @secretInput.focus()
        #document.body.appendChild @previousInput
        
        #@nextInput = createSecretInput()
        #@nextInput.onfocus = () =>
        #    @advanceCursor()
        #    @secretInput.focus()
        #document.body.appendChild @nextInput
        
        @secretInput = createSecretInput()
        @secretInput.onkeydown = (e) => @processInput e
        # TODO: When @secretInput looses focus, maybe grey-out current word
        hiddenContainer.appendChild @secretInput
        @repositionSecretInputs()
        
        @cursorSpan = document.createElement('span')
        @cursorSpan.className = 'cursor'
        @cursorSpan.style['position'] = 'absolute'
        hiddenContainer.appendChild @cursorSpan
        
        for cell in @cells
            cell.addEventListener 'click', (event) =>
                if @isEntryCell event.target
                    @repositionSecretInputs()
                    @focus event.target
        
        @numberWords()
        
        @_wordsAtCell = new Map()
        for word in @words
            for cell in word.cells
                cellWords = @wordsAtCell cell
                cellWords.push word
                @_wordsAtCell.set cell, cellWords
        
        @number = 0
        @numberTimeStamp = 0
                
        @load()
    
    addCallback: (event, callback) ->
        @callbacks[event].push(callback)
        
    trigger: (event, data) ->
        for callback in @callbacks[event]
            callback(data, this)
    
    selectNextWord: (step = 1, skipComplete = false) ->
        startingIndex = @words.indexOf @currentWord
        return if startingIndex == -1
        
        index = ((startingIndex + step) % @words.length + @words.length) % @words.length
        while index != startingIndex
            word = @words[index]
            if word.clue? and (not skipComplete or not word.isComplete)
                @currentWord = word
                return
            index = ((index + step) % @words.length + @words.length) % @words.length
        
        # If no un-completed word exists, select the next clued word
        @selectNextWord(step, false) if skipComplete
        return
    
    explicitNumbers: ->
        cell.getAttribute('data-explicit-number') for cell in @cells when cell.hasAttribute('data-explicit-number')
    
    unnumberCells: ->
        for cell in @cells
            cell.removeAttribute('data-cell-number')
    
    # TODO: A more elegant way of setting the standard for numbering?
    numberWords: (words = @words.filter((word) => word.clue?)) ->
        cellNumberGenerator = do (exclude = @explicitNumbers()) ->
            num = 0
            loop
                num++
                number = num.toString()
                yield number unless (exclude.indexOf(number) >= 0)
            return
        
        for cell in @cells
            if (explicitNumber = cell.getAttribute('data-explicit-number'))?
                cell.setAttribute('data-cell-number', explicitNumber)
        
        for word in words.sort compareWordsDomOrder
            unless word.number?
                word.number = cellNumberGenerator.next().value
    
    renumber: ->
        @unnumberCells()
        @numberWords()
    
    cellWithNumber: (number) ->
        for cell in @cells
            if cell.getAttribute('data-cell-number') == number
                return cell
        return null
    
    wordsAtCell: (cell) ->
        return @_wordsAtCell.get(cell) or []
    
    repositionSecretInputs: ->
        # TODO: Repositioning of secret input
        #@secretInput.style['top'] = "#{@grid.offsetTop}px"
        #@secretInput.style['height'] = "#{@grid.offsetHeight}px"
    
    isEntryCell: (cell) -> cell? and cell.textContent != ""
    
    focus: (cell) ->
        words = @wordsAtCell cell
        if cell == @currentCell
            newWord = words[(words.indexOf(@currentWord) + 1) % words.length]
        else
            wordsWithClues = words.filter((word) => word.clue?)
            wordsStartingHere = wordsWithClues.filter((word) => word.startingCell == cell)
            newWord = (wordsStartingHere.concat wordsWithClues, words)[0]
        
        @currentWord = newWord
        @positionInWord = @currentWord.cells.indexOf cell
        @secretInput.focus()
        return
    
    cellChanged: (cell) ->
        @trigger 'changed', { cell: cell }
        for word in @wordsAtCell cell
            word.trigger 'changed'
    
    write: (content) ->
        # TODO: It might be nice to automatically grow the grid when a new cell is written at the end
        cell = @currentCell
        if (@isEntryCell cell) or (@features.writeNewCells and cell?)
            cell.textContent = content
            @cellChanged cell
            @positionInWord += 1
            if @currentWord.length == @positionInWord
                @currentWord.trigger('completed')
            return true
        else
            return false
    
    setBar: ->
        direction = @currentWord.direction
        index = @words.indexOf(@currentWord)
        @words.splice(index, 1)
        preWord = new Word @currentWord.cells.slice(0, @positionInWord), direction
        postWord = new Word @currentWord.cells.slice(@positionInWord), direction
        if preWord.length > 0
            @words.push preWord
            nextWord = preWord
            nextPosition = preWord.length
        if postWord.length > 0
            postWord.clue = "."
            @words.push postWord
            nextWord = postWord
            nextPosition = 0
        @words.sort compareWordsDomOrder # TODO: Change sort to clue-order
        @renumber()
        # Do this after renumbering so the right number is shown below the crossword immediately
        @currentWord = nextWord
        @positionInWord = nextPosition
        return
    
    processInput: (e) ->
        if e.metaKey or e.ctrlKey
            return
        
        e.preventDefault()
        preserveNumber = false
        inputProcessed = false
        
        for callbackResult in @trigger('input', { key: e.key }).reverse()
            if callbackResult?
                inputProcessed = true
                @write entry for entry in callbackResult
                break
        
        if not inputProcessed
            if "0" <= e.key <= "9"
                preserveNumber = true
                @number = 0 if e.timeStamp - @numberTimeStamp > 1000
                @numberTimeStamp = e.timeStamp
                @number *= 10
                @number += parseInt(e.key)
                if (cell = @cellWithNumber(@number))?
                    @focus cell
            else switch e.key
                when ' '
                    @focus @currentCell
                when 'ArrowRight'
                    console.log('TODO: Arrows')
                when 'ArrowLeft'
                    console.log('TODO: Arrows')
                when 'ArrowUp'
                    console.log('TODO: Arrows')
                when 'ArrowDown'
                    console.log('TODO: Arrows')
                when 'Tab'
                    if e.shiftKey
                        @selectNextWord(-1)
                    else
                        @selectNextWord(1, true)
                when 'Backspace'
                    cell = @currentWord.cells[@positionInWord - 1]
                    if @isEntryCell cell
                        cell.textContent = ' '
                        @cellChanged cell
                        @positionInWord -= 1
                when '|'
                    @setBar() if @features.setBars
                when 'Delete'
                    if @features.writeNewCells
                        @write ''

        @number = 0 unless preserveNumber
        
    clear: (clearStorage = true) ->
        for cell in @cells when cell.textContent != ''
            cell.textContent = ' '
        if clearStorage
            try
                console.warn('TODO: Move storage clearing')
                localStorage.removeItem("coffeeword-#{@saveId}-v1")
            catch
        return
    
    populateClues: ->
        for word in @words
            if word.clue == '.'
                word.clue = word.toString()
        return
    
    serializeStateV1: ->
        console.warn('serializeStateV1 is deprecated, use the version of serializeState with the highest number')
        (for row in @grid.rows
            (cell.textContent for cell in row.cells).join ','
        ).join ';'

    unserializeStateV1: (string) ->
        # This is slightly hacky because the Kreuzwort object does not keep a reference to its grid anymore,
        # but saved state from older version should not get lost.
        grid = @cells[0].parentElement.parentElement
        for rowString, row in string.split(';')
            for cellString, col in rowString.split(',')
                grid.rows[row].cells[col].textContent = cellString
        return
    
    serializeStateV2: ->
        console.warn('serializeStateV2 is deprecated, use the version of serializeState with the highest number')
        (for row in @grid.rows
            (for cell in row.cells
                switch cell.textContent
                    when ' ' then '_'
                    when '' then '.'
                    else cell.textContent
            ).join ''
        ).join '-'
    
    unserializeStateV2: (string) ->
        # This is slightly hacky because the Kreuzwort object does not keep a reference to its grid anymore,
        # but saved state from older version should not get lost.
        grid = @cells[0].parentElement.parentElement
        for rowString, row in string.split('-')
            for cellString, col in rowString.split('')
                grid.rows[row].cells[col].textContent = switch cellString
                    when '_' then ' '
                    when '.' then ''
                    else cellString
        return
    
    serializeStateV3: ->
        (cell.textContent for cell in @cells).join('-')
    
    unserializeStateV3: (string) ->
        cellStrings = string.split('-')
        for cell, cellIndex in @cells # filter instead of when keyword makes indices line up
            cell.textContent = cellStrings[cellIndex]
        return
    
    save: -> 
        if @saveId?
            try 
                #localStorage.setItem("kreuzwort-#{@saveId}-v2", @serializeStateV2())
                localStorage.setItem("kreuzwort-#{@saveId}-v3", @serializeStateV3())
            catch
    
    load: ->
        return unless @saveId?
        loaders = [
            { key: "kreuzwort-#{@saveId}-v3", fun: @unserializeStateV3 },
            { key: "kreuzwort-#{@saveId}-v2", fun: @unserializeStateV2 },
            { key: "crossword-#{@saveId}-v1", fun: @unserializeStateV1 }
            ]
        params = new URL(location).searchParams
        for { key, fun } in loaders
            if params.has key
                fun.bind(this)(params.get(key))
                return
        try
            for { key, fun } in loaders
                if (string = localStorage.getItem(key))?
                    fun.bind(this)(string)
                    return
        catch
            # I don’t think we can do anything useful when local storage does not work
        return
    
    progressURL: ->
        url = new URL(location)
        url.searchParams.set("#{@saveId}-v2", @saveV2())
        return url
    
    check: ->
        console.warn('TODO: make checking work again')
        solutionHash = @grid.getAttribute('data-solution-hash-v1')
        return solutionHash == @currentHash()
    
    currentHash: ->
        hash @saveV1()
    
    gridHTML: () ->
        console.warn('TODO: find better solution for grid creation')
        word = @currentWord
        @currentWord = null
        @grid.setAttribute('data-solution-hash-v1', @currentHash())
        @unnumberCells()
        for cell in @grid.querySelectorAll("td[class='']")
            cell.removeAttribute('class')
        @populateClues()
        temp = @saveV1()
        @clear false
        html = @grid.outerHTML
        @loadV1(temp)
        @numberWords()
        @currentWord = word
        return html

    cellNumbersForDirection: (direction) ->
        for word in @words.filter((word) => word.direction == direction) when word.clue?
            word.number
    
    fillCluesFromArrayForDirection: (clues, direction) ->
        words = @words.filter((word) => word.clue? and word.direction == direction)
        for clue, index in clues
            words[index]?.clue = clue
    
    fillCluesFromTextForDirection: (text, direction) ->
        cellNumbers = @cellNumbersForDirection(direction)
        re = wordStartsToRegExp(cellNumbers)
        clues = re.exec(text).splice(1)
        @fillCluesFromArrayForDirection(clues, direction)
    
    clueWordsAtLeastLong: (n) ->
        for word in @words
            if word.length >= n
                word.clue = '.'
        @numberWords()

    clueListingForDirection: (direction) ->
        ol = document.createElement('ol')
        for word in @words when word.direction == direction
            continue unless word.clue?
            
            li = document.createElement('li')
            li.value = word.number
            do (li) =>
                word.addCallback 'selected', =>
                    li.classList.add 'current-clue'
                word.addCallback 'unselected', =>
                    li.classList.remove 'current-clue'
            li.innerHTML = word.clue
            li.setAttribute('data-enumeration', word.length)
            li.setAttribute('data-partial-solution', word.toString()) unless word.isEmpty
            
            if word.isComplete
                li.classList.add 'complete'
            do (li) =>
                word.addCallback 'changed', (_, word) =>
                    if word.isComplete
                        li.classList.add 'complete'
                    else
                        li.classList.remove 'complete'
                    if word.isEmpty
                        li.removeAttribute 'data-partial-solution'
                    else
                        li.setAttribute 'data-partial-solution', word.toString()
            do (word) =>
                li.onclick = () =>
                    @currentWord = word
                    @secretInput.focus()
            ol.appendChild li
        return ol
    
    @featuresFull:
        writeNewCells: false
        setBars: false
    
    @featuresConstruction:
        writeNewCells: true
        setBars: true
    
    @horizontal:
        toString: () => "horizontal"
        advance: (cursor) =>
            if cursor? then { row: cursor.row, col: cursor.col + 1 } else null
        retrogress: (cursor) =>
            if cursor? then { row: cursor.row, col: cursor.col - 1 } else null
        before: 'left'
        after: 'right'
        other: null

    @vertical:
        toString: () => "vertical"
        advance: (cursor) =>
            if cursor? then { row: cursor.row + 1, col: cursor.col } else null
        retrogress: (cursor) =>
            if cursor? then { row: cursor.row - 1, col: cursor.col } else null
        before: 'top'
        after: 'bottom'
        other: Kreuzwort.horizontal

Kreuzwort.horizontal.other = Kreuzwort.vertical

Object.defineProperties Kreuzwort.prototype,
    currentCell:
        get: -> @currentWord?.cells[@positionInWord]
    currentWord:
        get: -> @_currentWord
        set: (newWord) ->
            if newWord != @_currentWord
                @_currentWord?.removeClass()
                @_currentWord?.trigger 'unselected'
                @_currentWord = newWord
                @_currentWord?.addClass() if @_currentWord?.clue?
                @_currentWord?.trigger 'selected'
                @positionInWord = @_currentWord?.firstEmptyPosition
    numberOfBlacks:
        get: -> @cells.filter((cell) => cell.textContent == '').length
    numberOfClues:
        get: -> @words.filter((word) => word.clue?).length
    numberOfWhites:
        get: -> @cells.filter((cell) => cell.textContent != '').length
    positionInWord:
        get: -> @_positionInWord
        set: (newPosition) ->
            # TODO: I’m still not sure whether the cursor should be a class on the current cell or a moving span
            # Pros of the class
            # - cursor updates automatically when window resizes
            # - more controll for the designer
            # - less code here
            # Pros of the moving span
            # - easier support for cells that are not 1x1
            # - less work for the designer
            # - using classes for everything might strain the ::before and ::after pseudo elements (cell-number, cursor and markings for hyphens/spaces would be to much)
            @_positionInWord = newPosition
            @trigger 'selectionChanged', { word: @_currentWord, position: @_positionInWord }

            if 0 <= newPosition < @currentWord.length
                cell = @currentWord.cells[newPosition]
                top = cell.offsetTop + 1
                left = cell.offsetLeft + 1
            else if newPosition == @currentWord.length
                cell = @currentWord.cells[newPosition - 1]
                top = cell.offsetTop + if @currentWord.direction == Kreuzwort.vertical then cell.offsetHeight - 3 else 1
                left = cell.offsetLeft + if @currentWord.direction == Kreuzwort.horizontal then cell.offsetWidth - 3 else 1
        
            @cursorSpan.style['top'] = "#{top}px"
            @cursorSpan.style['left'] = "#{left}px"
        
            if @currentWord.direction == Kreuzwort.horizontal
                @cursorSpan.style['width'] = "3px"
                @cursorSpan.style['height'] = "#{cell.offsetHeight - 1}px"
            else if @currentWord.direction == Kreuzwort.vertical
                @cursorSpan.style['width'] = "#{cell.offsetWidth - 1}px"
                @cursorSpan.style['height'] = "3px"

hash = (string) =>
    h = 0
    if string.length == 0
        return h
    for char in string
        c = char.charCodeAt()
        h = ((h << 5) - h) + c
        h = h & h # Convert to 32bit integer
    return h.toString()

toClipboard = (string) =>
    textarea = document.createElement 'textarea'
    textarea.value = string
    document.body.appendChild textarea
    textarea.select()
    document.execCommand('copy')
    document.body.removeChild textarea

createSecretInput = (outline) ->
    secretInput = document.createElement('input')
    secretInput.style['position'] = 'absolute'
    secretInput.style['margin'] = '0'
    secretInput.style['padding'] = '0'
    secretInput.style['border'] = 'none'
    secretInput.style['outline'] = "1px solid #{outline}"
    secretInput.style['left'] = '-10000px'
    return secretInput

# TODO: This might fail if words start on cells that are not 1x1.
compareWordsDomOrder = (wordA, wordB) ->
    cellA = wordA.startingCell
    cellB = wordB.startingCell
    rowDiff = cellA.parentElement.rowIndex - cellB.parentElement.rowIndex
    if rowDiff != 0
        return rowDiff
    else
        return cellA.cellIndex - cellB.cellIndex

standardLetters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".split ""
standardInputCallback = (e) ->
    if (standardLetters.indexOf e.key) >= 0
        [e.key.toUpperCase()]
    else
        null

wordStartsToRegExp = (starts) ->
    new RegExp((starts.join '([^]*)') + '([^].*)')

window.fromGrid = (grid) ->
    table = document.createElement 'table'
    rows = grid.trim().split '\n'
    prevRow = []
    for row in rows
        tr = document.createElement 'tr'
        cells = row.trim().split ''
        prevCell = '.'
        for cell, colNum in cells
            td = document.createElement 'td'
            if cell == '.'
                td.innerHTML = ''
            else if cell == 'X'
                td.innerHTML = '&nbsp;'
            else
                td.innerHTML = cell
            tr.appendChild td
            prevCell = cell
        table.appendChild tr
        prevRow = row
    return table

window.tableCellMatrix = (table) ->
    m = []
    for rowElem, row in table.rows
        col = 0
        m[row] = [] unless m[row]?
        for cell in rowElem.cells
            col++ while m[row][col]?
            for i in [0...(cell.rowSpan or 1)]
                for j in [0...(cell.colSpan or 1)]
                    m[row + i] = [] unless m[row + i]?
                    m[row + i][col + j] = cell
    return m

constFalse = -> false
standardBlockTest = (cell) -> cell.textContent == ''

window.cellMatrixToWordList = (matrix, direction, hasBarBefore = constFalse, isBlock = standardBlockTest) ->
    words = []
    currentCells = []
    isInBounds = (cursor) =>
        cursor.row < matrix.length and cursor.col < matrix[0].length
    pushWord = =>
        if currentCells.length > 0
            words.push (new Word currentCells, direction)
            currentCells = []
    
    lineStart = { row: 0, col: 0 }
    while isInBounds lineStart
        currentCursor = lineStart
        while isInBounds currentCursor
            currentCell = matrix[currentCursor.row][currentCursor.col]
            if isBlock(currentCell) or hasBarBefore(currentCell)
                pushWord()
            if not isBlock(currentCell) and (currentCells[currentCells.length - 1] != currentCell)
                currentCells.push currentCell
            currentCursor = direction.advance currentCursor
        pushWord()
        lineStart = direction.other.advance lineStart
    
    words.sort compareWordsDomOrder
    return words

# TODO: make this a static method of Kreuzwort?
window.kreuzwortFromGrid = (grid, saveId, hiddenContainer) =>
    cells = grid.querySelectorAll('td')
    cellMatrix = tableCellMatrix grid
    words = cellMatrixToWordList(cellMatrix, Kreuzwort.horizontal, (cell) => 
            cell.hasAttribute("data-clue-horizontal")
        ).concat cellMatrixToWordList(cellMatrix, Kreuzwort.vertical, (cell) => 
            cell.hasAttribute("data-clue-vertical"))
    return new Kreuzwort(cells, words, saveId, undefined, hiddenContainer)
    

window.Kreuzwort = Kreuzwort
