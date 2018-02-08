# Cursor: row, col and (writing) direction
# Cell: an actual DOM cell
# Word: collection of cells and corresponding clue
horizontal =
    toString: () => "horizontal"
    advance: (cursor) =>
        if cursor? then { row: cursor.row, col: cursor.col + 1 } else null
    retrogress: (cursor) =>
        if cursor? then { row: cursor.row, col: cursor.col - 1 } else null
    before: 'left'
    after: 'right'
    other: null

vertical =
    toString: () => "vertical"
    advance: (cursor) =>
        if cursor? then { row: cursor.row + 1, col: cursor.col } else null
    retrogress: (cursor) =>
        if cursor? then { row: cursor.row - 1, col: cursor.col } else null
    before: 'top'
    after: 'bottom'
    other: horizontal

horizontal.other = vertical

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

#window.toQueryString = (string) ->
#    params = new URLSearchParams()
#    params.append('q', string)
#    return params.toString().substr(2)

strings =
    checkSolution: 'checkSolution'
    solutionCorrect: 'solutionCorrect'
    solutionIncorrect: 'solutionIncorrect'
    reset: 'reset'
    resetConfirmation: 'resetConfirmation'
    horizontal: 'horizontal'
    vertical: 'vertical'
    showHTML: 'showHTML'
    copyHTML: 'copyHTML'
    hideHTML: 'hideHTML'
    noClue: 'noClue'
    print: 'print'
    printEmpty: 'printEmpty'

english =
    checkSolution: 'Check Solution'
    solutionCorrect: 'The solution is correct.'
    solutionIncorrect: 'The crossword is incomplete or the solution is incorrect.'
    reset: 'Reset Crossword'
    resetConfirmation: 'Do you want to completely reset the crossword?'
    horizontal: 'Across'
    vertical: 'Down'
    showHTML: 'Show Grid HTML'
    copyHTML: 'Copy HTML to Clipboard'
    hideHTML: 'Hide Grid HTML'
    noClue: 'No clue in this direction'
    print: 'Print'
    printEmpty: 'Print Empty Grid'

german =
    checkSolution: 'Lösung prüfen'
    solutionCorrect: 'Super, alles richtig.'
    solutionIncorrect: 'Leider ist noch nicht alles richtig.'
    reset: 'Alles löschen'
    resetConfirmation: 'Soll das Rätsel vollständig zurückgesetzt werden?'
    horizontal: 'Waagerecht'
    vertical: 'Senkrecht'
    showHTML: 'Gitter-HTML anzeigen'
    copyHTML: 'HTML in die Zwischenablage'
    hideHTML: 'Gitter-HTML ausblenden'
    noClue: 'Kein Hinweis in diese Richtung'
    print: 'Drucken'
    printEmpty: 'Leer drucken'

class Kreuzwort
    @Word: class Word
        constructor: (@cells, @clue, @number, @direction, @explanation) ->
            @callbacks =
                changed: [ ]
                selected: [ ]
                unselected: [ ]
            @length = @cells.length
        
        addCallback: (event, callback) ->
            @callbacks[event].push(callback)
        
        trigger: (event, data) ->
            for callback in @callbacks[event]
                callback(data, this)
        
        toString: ->
            (for cell in @cells
                if cell.innerHTML == '&nbsp;'
                    '␣'
                else
                    unsolved = false
                    cell.innerHTML).join ''
        
        isEmpty: ->
            for cell in @cells
                return false unless cell.textContent == ' '
            return true
            
        isComplete: ->
            for cell in @cells
                return false if cell.textContent == ' '
            return true
    
    @instances: []
    
    constructor: (@grid, @saveId, @features = Kreuzwort.featuresFull, @strings = strings) ->
        Kreuzwort.instances.push this
        
        @callbacks =
            changed: [ ]
            input: [ standardInputCallback ]
            save: [ @saveV1.bind(this) ]
            wordSelected: [ ]
        @words =
            horizontal: []
            vertical: []

        @cellMatrix = tableCellMatrix @grid

        @previousInput = createSecretInput()
        @previousInput.onfocus = () =>
            @retrogressCursor()
            @secretInput.focus()
        document.body.appendChild @previousInput
        
        @secretInput = createSecretInput()
        @secretInput.onblur = =>
            @blur()
        document.body.appendChild @secretInput
        
        @nextInput = createSecretInput()
        @nextInput.onfocus = () =>
            @advanceCursor()
            @secretInput.focus()
        document.body.appendChild @nextInput

        for cell in @grid.querySelectorAll 'td'
            cell.addEventListener 'click', (event) =>
                if @isEntryCell event.target
                    @repositionSecretInputs()
                    @focus event.target
        
        @renumberStartingCells()
        
        for direction in [horizontal, vertical]
            for cell in @startsForDirection direction
                @words[direction].push @wordStartingAtCellInDirection cell, direction
        
        elementAfterGrid = @grid.nextSibling
        
        @cursor = null
        @direction = horizontal
        @currentWord = null
        @positionInWord = 0
        
        @secretInput.onkeydown = (e) => @processInput e
        @repositionSecretInputs()
        
        @number = 0
        @numberTimeStamp = 0
                
        @load()
    
    addCallback: (event, callback) ->
        @callbacks[event].push(callback)
        
    trigger: (event, data) ->
        for callback in @callbacks[event]
            callback(data, this)
    
    startingCells: ->
        @grid.querySelectorAll("""
            td[data-clue-vertical]:not([data-clue-vertical='']),
            td[data-clue-horizontal]:not([data-clue-horizontal=''])
            """)
    
    renumberStartingCells: ->
        cellNumberGenerator = do (exclude = []) ->
            num = 0
            loop
                num++
                number = num.toString()
                yield number unless (exclude.indexOf(number) >= 0)
            return
        
        for cell in @startingCells()
            cell.setAttribute('data-cell-number', cellNumberGenerator.next().value)
        
    
    startsForDirection: (direction) ->
        @grid.querySelectorAll("td[data-clue-#{direction}]:not([data-clue-#{direction}=''])")
    
    cellNumbersForDirection: (direction) ->
        for cell in @startsForDirection direction
            cell.getAttribute('data-cell-number')
    
    fillCluesFromArrayForDirection: (clues, direction) ->
        cells = @startsForDirection direction
        for clue, index in clues
            cells.item(index)?.setAttribute("data-clue-#{direction}", clue);
    
    fillCluesFromTextForDirection: (text, direction) ->
        cellNumbers = @cellNumbersForDirection(direction)
        re = wordStartsToRegExp(cellNumbers)
        clues = re.exec(text).splice(1)
        @fillCluesFromArrayForDirection(clues, direction)
    
    clueWordsAtLeastLong: (n) ->
        cellNumberGenerator = do (exclude = []) ->
            num = 0
            loop
                num++
                number = num.toString()
                yield number unless (exclude.indexOf(number) >= 0)
            return
        
        for row in @grid.rows
            for cell in row.cells
                for direction in [horizontal, vertical]
                    word = @wordStartingAtCellInDirection cell, direction
                    if word? and word.cells.length >= n
                        cell.setAttribute "data-clue-#{direction}", '.'
                        unless cell.hasAttribute 'data-cell-number'
                            number = cellNumberGenerator.next().value
                            cell.setAttribute 'data-cell-number', number
                            word.number = number
                        word.clue = '.'
                        @words[direction].push word
        
        @renumberStartingCells()
    
    cellWithNumber: (number) ->
        @startingCells()[number - 1]
    
    repositionSecretInputs: ->
        @nextInput.style['top'] = @secretInput.style['top'] = @previousInput.style['top'] = "#{@grid.offsetTop}px"
        @nextInput.style['height'] = @secretInput.style['height'] = @previousInput.style['height'] = "#{@grid.offsetHeight}px"
    
    advanceCursor: ->
        @setCursor(@direction.advance(@cursor))
    
    retrogressCursor: ->
        @setCursor(@direction.retrogress(@cursor))
    
    cellAfter: (cursor = @cursor) ->
        if cursor?
            @cellMatrix[cursor.row]?[cursor.col]
        else
            null
    
    cellBefore: (cursor = @cursor, direction = @direction) ->
        @cellAfter(direction.retrogress(cursor))
    
    cursorAt: (cell) ->
        row: cell.parentElement.rowIndex
        col: cell.cellIndex
    
    getClue: (cell, direction) ->
        clue = cell?.getAttribute("data-clue-#{direction}")
        return (if clue? and clue != "" then clue else null)
        
    isEntryCell: (cell) -> cell? and cell.textContent != ""
        
    wordStartingAtCellInDirection: (cell, direction) ->
        return null unless cell?
        
        cursor = @cursorAt cell
        unless (@isEntryCell cell) and (@isWordBorder cursor, direction)
            return null
        
        cells = [cell]
        cursor = direction.advance cursor
        until @isWordBorder(cursor, direction)
            cells.push(@cellAfter(cursor, direction))
            cursor = direction.advance cursor
        
        return new Kreuzwort.Word(
            cells, 
            @getClue(cell, direction), 
            cell.getAttribute('data-cell-number'), 
            direction, 
            cell.getAttribute("data-explanation-#{direction}"))
    
    wordAtCell: (cell, direction) ->
        # TODO: This linear search should be fast enough for usual crossword sizes. However, a better data structure allowding direct access to the words of a cell would be nice anyways.
        for word in @words[direction]
            if word.cells.indexOf(cell) >= 0
                return word
        return null
    
    wordAfterCursor: (cursor = @cursor, direction = @direction) ->
        searchCell = @cellAfter cursor, direction
        @wordAtCell searchCell, direction
    
    wordBeforeCursor: (cursor = @cursor, direction = @direction) ->
        @wordAtCell (@cellBefore cursor, direction), direction
    
    clueListingForDirection: (direction, includeEnumerations = true) ->
        ol = document.createElement('ol')
        for word in @words[direction]
            li = document.createElement('li')
            li.value = word.number
            start = word.cells[0]
            do (li) =>
                word.addCallback 'selected', =>
                    li.classList.add 'current-clue'
                word.addCallback 'unselected', =>
                    li.classList.remove 'current-clue'
            li.innerHTML = word.clue
            
            if word.isComplete()
                li.classList.add 'complete'
            do (li) =>
                word.addCallback 'changed', (_, word) =>
                    if word.isComplete()
                        li.classList.add 'complete'
                    else
                        li.classList.remove 'complete'

            if includeEnumerations
                li.appendChild document.createTextNode ' '
                extraInfoSpan = document.createElement 'span'
                extraInfoSpan.className = 'extra-info'
                renderExtraInfo = (span, word) ->
                    if word.isEmpty()
                        span.innerHTML = "(#{word.length})"
                    else
                        span.innerHTML = "(#{word.length}<span>, #{word}</span>)"
                renderExtraInfo extraInfoSpan, word
                li.appendChild extraInfoSpan
                do (extraInfoSpan) =>
                    word.addCallback 'changed', (data, word) =>
                        renderExtraInfo extraInfoSpan, word
            do (start) =>
                li.onclick = () =>
                    @focus start, direction
            ol.appendChild li
        return ol
    
    blur: (fullBlur = false) ->
        if fullBlur and @currentWord?
            for cell in @currentWord.cells
                cell.classList.remove("current-word")
        return
    
    hasFocus: ->
        @secretInput == document.activeElement
    
    isWordBorder: (cursor, direction = @direction) ->
        beforeCell = @cellBefore(cursor, direction)
        afterCell = @cellAfter(cursor, direction)
        
        afterCell?.hasAttribute("data-clue-#{direction}") or
            not @isEntryCell(afterCell) or not @isEntryCell(beforeCell)
    
    setCursor: (cursor, direction = @direction) ->
        @cellAfter()?.classList.remove("cursor-top", "cursor-left")
        @cellBefore()?.classList.remove("cursor-bottom", "cursor-right")
        @cursor = cursor
        @direction = direction
        @cellAfter()?.classList.add "cursor-#{direction.before}"
        @cellBefore()?.classList.add "cursor-#{direction.after}"

        newWord = @wordAfterCursor cursor, direction
        return if newWord == @currentWord
        
        @blur true
        @currentWord?.trigger 'unselected'
        @currentWord = newWord
        
        if @currentWord?.clue?
            for cell in @currentWord.cells
                cell.classList.add('current-word')

        @currentWord?.trigger 'selected'
        @trigger 'wordSelected', @currentWord
        return
    
    focus: (cell, newDirection) ->
        cursor = @cursorAt cell
        unless newDirection?
            wordOnlyInOtherDirection = 
                not @wordAfterCursor(cursor, @direction)?.clue? and
                @wordAfterCursor(cursor, @direction.other)?.clue?
            wordStartOnlyInOtherDirection =
                not @getClue(cell, @direction)? and
                @getClue(cell, @direction.other)?
            
            if cell == @cellAfter() or
                    wordOnlyInOtherDirection or
                    wordStartOnlyInOtherDirection
                newDirection = @direction.other
            else
                newDirection = @direction
        
        @setCursor(cursor, newDirection)
        @secretInput.focus()
        return
    
    cellChanged: (cell) ->
        @trigger 'changed'
        @wordAtCell(cell, horizontal)?.trigger 'changed'
        @wordAtCell(cell, vertical)?.trigger 'changed'
    
    processInput: (e) ->
        if e.metaKey or e.ctrlKey
            return
        
        preventDefault = true
        preserveNumber = false
        inputProcessed = false
        
        for callbackResult in @trigger('input', { key: e.key }).reverse()
            if callbackResult?
                inputProcessed = true
                for entry in callbackResult
                    cell = @cellAfter()
                    if (@isEntryCell cell) or @features.writeNewCells
                        cell.textContent = entry
                        @cellChanged cell
                        @advanceCursor()
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
                    @setCursor(@cursor, @direction.other)
                when 'ArrowRight'
                    @setCursor(horizontal.advance @cursor)
                when 'ArrowLeft'
                    @setCursor(horizontal.retrogress @cursor)
                when 'ArrowUp'
                    @setCursor(vertical.retrogress @cursor)
                when 'ArrowDown'
                    @setCursor(vertical.advance @cursor)
                when 'Tab'
                    # TODO: Make this nicer. What if no word is currently selected? Probably, the last word was completed, but a new word did not start immediately (end of line or bloek or non-perfect grid). Tab should jump to the next word.
                    wordIndex = @words[@currentWord.direction].indexOf(@currentWord)
                    wordIndex += if e.shiftKey then (-1) else 1
                    nextWord = if 0 <= wordIndex < @words[@currentWord.direction].length
                            @words[@currentWord.direction][wordIndex]
                        else if @words[@currentWord.direction.other].length > 0
                            if wordIndex >= 0
                                @words[@currentWord.direction.other][0]
                            else
                                @words[@currentWord.direction.other][(@words[@currentWord.direction.other].length) - 1]
                        else
                            @words[@currentWord.direction][0]
                    @focus(nextWord.cells[0], nextWord.direction)
                when 'Backspace'
                    cell = @cellBefore()
                    if @isEntryCell cell
                        cell.innerHTML = '&nbsp;'
                        @cellChanged cell
                        @retrogressCursor()
                when 'Enter'
                    if @features.setBars
                        cell = @cellAfter()
                        attr = "data-clue-#{@direction}"
                        switch cell.getAttribute(attr)
                            when ''
                                cell.removeAttribute(attr)
                            when null
                                cell.setAttribute(attr, '.')
                            else
                                cell.setAttribute(attr, '')
                    else
                        preventDefault = false
                when 'Delete'
                    if @features.writeNewCells
                        cell = @cellAfter()
                        cell.innerHTML = ''
                        @cellChanged cell
                        @advanceCursor()
                    else
                        preventDefault = false
                else
                    preventDefault = false
        
        @save()
        e.preventDefault() if preventDefault
        @number = 0 unless preserveNumber
        
    clear: (clearStorage = true) ->
        for cell in @grid.querySelectorAll('td:not(:empty)')
            cell.innerHTML = "&nbsp;"
        if clearStorage
            try
                localStorage.removeItem("coffeeword-#{@saveId}-v1")
            catch
        return
    
    populateClues: ->
        for cell in @startingCells()
            if cell.getAttribute("data-clue-vertical") == '.'
                cell.setAttribute("data-clue-vertical", @wordStartingAtCellInDirection(cell, vertical))
            if cell.getAttribute("data-clue-horizontal") == '.'
                cell.setAttribute("data-clue-horizontal", @wordStartingAtCellInDirection(cell, horizontal))
        return
    
    saveV1: ->
        saveString = (for row in @grid.rows
            (cell.textContent for cell in row.cells).join ','
        ).join ';'
        try
            localStorage.setItem("coffeeword-#{@saveId}-v1", saveString)
        catch e
        saveString
    
    saveV2: ->
        saveString = (for row in @grid.rows
            (for cell in row.cells
                switch cell.textContent
                    when ' ' then '_'
                    when '' then '.'
                    else cell.textContent
            ).join ''
        ).join '-'
    
    loadV1: (string) ->
        for rowString, row in string.split(';')
            for cellString, col in rowString.split(',')
                @cellAfter({row, col}).textContent = cellString
        return
    
    loadV2: (string) ->
        for rowString, row in string.split('-')
            for cellString, col in rowString.split('')
                @cellAfter({row, col}).textContent = switch cellString
                    when '_' then ' '
                    when '.' then ''
                    else cellString
        return
    
    save: -> @trigger('save')
    
    load: ->
        try
            params = new URL(location).searchParams
            if params.has("#{@saveId}-v2")
                @loadV2(params.get("#{@saveId}-v2"))
            else if params.has("#{@saveId}-v1")
                @loadV1(params.get("#{@saveId}-v1"))
            else
                @loadV1(localStorage.getItem("coffeeword-#{@saveId}-v1"))
        catch e
            console.log(e)
    
    progressURL: ->
        url = new URL(location)
        url.searchParams.set("#{@saveId}-v2", @saveV2())
        return url
    
    check: ->
        solutionHash = @grid.getAttribute('data-solution-hash-v1')
        return solutionHash == @currentHash()
    
    currentHash: ->
        hash @saveV1()
    
    gridHTML: () ->
        @blur()
        @grid.setAttribute('data-solution-hash-v1', @currentHash())
        @populateClues()
        temp = @saveV1()
        @clear false
        html = @grid.outerHTML
        @loadV1(temp)
        return html

    @featuresFull:
        writeNewCells: false
        setBars: false
    
    @featuresCompact:
        writeNewCells: false
        setBars: false
    
    @featuresConstruction:
        writeNewCells: true
        setBars: true
    
    @languages:
        english: english
        german: german
    
    @horizontal: horizontal
    @vertical: vertical

window.Kreuzwort = Kreuzwort

window.kreuzwortAutoSetup = (container) =>
    grid = container.querySelector('table')
    elementAfterGrid = grid.nextElementSibling
    kreuzwort = new Kreuzwort(grid, container.id, Kreuzwort.featuresFull)
    # TODO: Better way to choose this automatically (HTML lang attribute?)
    localStrings = german
    
    currentClueDiv = document.createElement 'p'
    currentClueDiv.className = 'current-clue'
    currentClueDiv.hidden = true
    kreuzwort.addCallback('wordSelected', (word) =>
        currentClueDiv.innerHTML = 
            if word?.clue?
                """<span class="current-word-position">
                        #{localStrings[word.direction]}, #{word.number}
                    </span>
                    #{word.clue}
                    """
            else
                "<i>#{localStrings.noClue}</i>"
        currentClueDiv.hidden = false
        )
    container.insertBefore currentClueDiv, elementAfterGrid
    
    controlsDiv = document.createElement 'div'
    controlsDiv.className = 'controls'
    
    checkButton = document.createElement 'button'
    checkButton.textContent = localStrings.checkSolution
    checkButton.addEventListener 'click', =>
        if kreuzwort.check()
            alert localStrings.solutionCorrect
        else
            alert localStrings.solutionIncorrect
    controlsDiv.append checkButton
    controlsDiv.append ' '
    
    clearButton = document.createElement 'button'
    clearButton.textContent = localStrings.reset
    clearButton.addEventListener 'click', =>
        if confirm(localStrings.resetConfirmation)
            kreuzwort.clear()
    controlsDiv.append clearButton
    controlsDiv.append ' '

    unless container.classList.contains 'compact'
        printEmptyButton = document.createElement 'button'
        printEmptyButton.textContent = localStrings.printEmpty
        printEmptyButton.addEventListener 'click', =>
            temp = kreuzwort.saveV1()
            kreuzwort.clear()
            window.print()
            Promise.resolve().then => (kreuzwort.loadV1(temp); kreuzwort.save())
        controlsDiv.append printEmptyButton
        controlsDiv.append ' '
        
        printFullButton = document.createElement 'button'
        printFullButton.textContent = localStrings.print
        printFullButton.addEventListener 'click', => window.print()
        controlsDiv.append printFullButton
        controlsDiv.append ' '
    
    if container.classList.contains 'construction'
        createButton = document.createElement 'button'
        createButton.textContent = localStrings.copyHTML
        createButton.addEventListener 'click', => toClipboard(kreuzwort.gridHTML())
        controlsDiv.append createButton
        controlsDiv.append ' '
    
    if controlsDiv.hasChildNodes()
        container.insertBefore controlsDiv, elementAfterGrid
    
    unless container.classList.contains('compact')
        directions = [horizontal, vertical]
        for direction in directions
            head = document.createElement 'h2'
            head.textContent = localStrings[direction]
            container.insertBefore head, elementAfterGrid
            container.insertBefore (kreuzwort.clueListingForDirection direction), elementAfterGrid
    
    return kreuzwort

window.addEventListener 'load', () =>
    document.querySelectorAll('.kreuzwort').forEach kreuzwortAutoSetup
    
