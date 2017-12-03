# Cursor: row, col and (writing) direction
# Cell: an actual DOM cell
# Word: collection of cells and corresponding hint
horizontal =
    toString: () => "horizontal"
    #display: 'Waagerecht'
    advance: (cursor) =>
        if cursor? then { row: cursor.row, col: cursor.col + 1 } else null
    retrogress: (cursor) =>
        if cursor? then { row: cursor.row, col: cursor.col - 1 } else null
    before: 'left'
    after: 'right'
    other: null

vertical =
    toString: () => "vertical"
    #display: 'Senkrecht'
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

strings =
    checkSolution: 'checkSolution'
    solutionCorrect: 'solutionCorrect'
    solutionIncorrect: 'solutionIncorrect'
    reset: 'reset'
    resetConfirmation: 'resetConfirmation'
    horizontal: 'horizontal'
    vertical: 'vertical'
    showHTML: 'showHTML'
    hideHTML: 'hideHTML'
    noHint: 'noHint'
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
    hideHTML: 'Hide Grid HTML'
    noHint: 'There is no hint in this direction.'
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
    hideHTML: 'Gitter-HTML ausblenden'
    noHint: 'Kein Hinweis in diese Richtung.'
    print: 'Drucken'
    printEmtpy: 'Leer drucken'

class Kreuzwort
    constructor: (@container, @features = Kreuzwort.featuresFull, @strings = strings) ->
        @grid = @container.querySelector('table')

        @previousInput = @createSecretInput('purple')
        @previousInput.onfocus = () =>
            @retrogressCursor()
            @secretInput.focus()
        @container.insertBefore(@previousInput, @grid)
        
        @secretInput = @createSecretInput('red')
        @secretInput.onblur = =>
            @blur()
        @container.insertBefore(@secretInput, @grid)
        
        @nextInput = @createSecretInput('navy')
        @nextInput.onfocus = () =>
            @advanceCursor()
            @secretInput.focus()
        @container.insertBefore(@nextInput, @grid)

        for cell in @grid.querySelectorAll 'td'
            do (cell) => cell.onclick = =>
                if @isEntryCell cell
                    @repositionSecretInputs()
                    @focus cell
        
        elementAfterGrid = @grid.nextSibling
        
        @currentHintDiv = document.createElement 'div'
        @currentHintDiv.className = 'current-hint'
        @currentHintDiv.hidden = true
        @container.insertBefore @currentHintDiv, elementAfterGrid
        
        controlsDiv = document.createElement 'div'
        controlsDiv.className = 'controls'
        
        firstFeature = true
        
        if @features.check
            if firstFeature
                firstFeature = false
            else
                controlsDiv.append ' • '
            checkButton = document.createElement 'a'
            checkButton.textContent = @strings.checkSolution
            checkButton.onclick = () =>
                if @check()
                    alert @strings.solutionCorrect
                else
                    alert @strings.solutionIncorrect
            controlsDiv.append checkButton
        
        if @features.clear
            if firstFeature
                firstFeature = false
            else
                controlsDiv.append ' • '
            clearButton = document.createElement 'a'
            clearButton.textContent = @strings.reset
            clearButton.onclick = =>
                if confirm(@strings.resetConfirmation)
                    @clear()
            controlsDiv.append clearButton

        if @features.print
            if firstFeature
                firstFeature = false
            else
                controlsDiv.append ' • '
            
            printFullButton = document.createElement 'a'
            printFullButton.textContent = @strings.print
            printFullButton.onclick = => window.print()
            controlsDiv.append printFullButton
            controlsDiv.append ' • '
            printEmptyButton = document.createElement 'a'
            printEmptyButton.textContent = @strings.printEmpty
            printEmptyButton.onclick = =>
                temp = @saveV1()
                @clear()
                window.print()
                window.setTimeout((=> @loadV1(temp); @save()), 1)
            controlsDiv.append printEmptyButton
        
        if @features.createGrid
            if firstFeature
                firstFeature = false
            else
                controlsDiv.append ' • '
            createButton = document.createElement 'a'
            createButton.textContent = @strings.showHTML
            createGridOutput = document.createElement 'textarea'
            showFunction = =>
                createGridOutput.style['position'] = 'absolute'
                createGridOutput.style['width'] = "#{@grid.offsetWidth}px"
                createGridOutput.style['height'] = "#{@grid.offsetHeight}px"
                createGridOutput.style['top'] = "#{@grid.offsetTop}px"
                createGridOutput.style['left'] = "#{@grid.offsetLeft}px"
                createGridOutput.textContent = @createGrid()
                @container.append createGridOutput
                createButton.textContent = @strings.hideHTML
                createButton.onclick = hideFunction
            hideFunction = =>
                createGridOutput.remove()
                createButton.textContent = @strings.showHTML
                createButton.onclick = showFunction
            createButton.onclick = showFunction
            controlsDiv.append createButton
            
        if controlsDiv.hasChildNodes()
            @container.insertBefore controlsDiv, elementAfterGrid
        
        if @features.hintListing
            directions = [horizontal, vertical]
            hintLists = {}
            for direction in directions
                head = document.createElement 'h2'
                head.textContent = @strings[direction]
                @container.insertBefore head, elementAfterGrid
                
                hintLists[direction] = document.createElement 'ol'
                @container.insertBefore hintLists[direction], elementAfterGrid
            
            cellNumber = 0
            for cell in @startingCells()
                cellNumber++
                for direction in directions
                    do (cell, direction) =>
                        hint = cell.getAttribute("data-hint-#{direction}")
                        if hint? and hint != ""
                            li = document.createElement 'li'
                            li.value = cellNumber.toString()
                            li.innerHTML = hint
                            li.onclick = () =>
                                @grid.scrollIntoView()
                                @focus cell, direction
                            hintLists[direction].append li
            
        @cursor = null
        @direction = horizontal
        @currentWord = []
        
        @container.onkeydown = (e) => @processInput e
        
        @number = 0
        @numberTimeStamp = 0
        @permissibleLetters =
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".split ''
        
        @constructionMode = @grid.hasAttribute('data-construction-mode')
        
        @load()
    
    startingCells: ->
        @grid.querySelectorAll("""
            td[data-hint-vertical]:not([data-hint-vertical='']),
            td[data-hint-horizontal]:not([data-hint-horizontal=''])
            """)
    
    cellWithNumber: (number) ->
        @startingCells()[number - 1]
    
    createSecretInput: (outline) ->
        secretInput = document.createElement('input')
        secretInput.style['position'] = 'absolute'
        secretInput.style['margin'] = '0'
        secretInput.style['padding'] = '0'
        secretInput.style['border'] = 'none'
        secretInput.style['outline'] = "1px solid #{outline}"
        #secretInput.style['z-index'] = '-1'
        secretInput.style['left'] = '-10000px'
        return secretInput
    
    repositionSecretInputs: ->
        @nextInput.style['top'] = @secretInput.style['top'] = @previousInput.style['top'] = "#{@grid.offsetTop}px"
        @nextInput.style['height'] = @secretInput.style['height'] = @previousInput.style['height'] = "#{@grid.offsetHeight}px"
    
    advanceCursor: ->
        @setCursor(@direction.advance(@cursor))
    
    retrogressCursor: ->
        @setCursor(@direction.retrogress(@cursor))
    
    cellAfter: (cursor = @cursor) ->
        if cursor?
            @grid.rows[cursor.row]?.cells[cursor.col]
        else
            null
    
    cellBefore: (cursor = @cursor, direction = @direction) ->
        @cellAfter(direction.retrogress(cursor))
    
    cursorAt: (cell) ->
        row: cell.parentElement.rowIndex
        col: cell.cellIndex
    
    hasHint: (cell, direction) ->
        hint = cell?.getAttribute("data-hint-#{direction}")
        return hint? and hint != ""
        
    isEntryCell: (cell) -> cell? and cell.textContent != ""
        
    wordAfterCursor: (cursor = @cursor, direction = @direction) ->
        until @isWordBorder(cursor, direction)
            cursor = direction.retrogress(cursor)
        
        startingCell = @cellAfter(cursor, direction)
        unless (@isEntryCell startingCell) and @hasHint startingCell, direction
            return []
        
        cells = [startingCell]
        cursor = direction.advance cursor
        until @isWordBorder(cursor, direction)
            cells.push(@cellAfter(cursor, direction))
            cursor = direction.advance cursor
        
        return cells
        
    blur: (fullBlur = false) ->
        @cellAfter()?.classList.remove("cursor-top", "cursor-left")
        @cellBefore()?.classList.remove("cursor-bottom", "cursor-right")
        
        window.setTimeout(
            (=> @cursor = null unless @hasFocus()),
            10)
        
        if fullBlur
            for cell in @currentWord
                cell.classList.remove("current-word")
            window.setTimeout(
                (=> @currentHintDiv.hidden = true unless @hasFocus()),
                10)
        return
    
    hasFocus: ->
        @secretInput == document.activeElement
    
    isWordBorder: (cursor, direction = @direction) ->
        beforeCell = @cellBefore(cursor, direction)
        afterCell = @cellAfter(cursor, direction)
        
        afterCell?.hasAttribute("data-hint-#{direction}") or
            not @isEntryCell(afterCell) or not @isEntryCell(beforeCell)
    
    getHint: (cell, direction) ->
        hint = cell?.getAttribute("data-hint-#{direction}")
        
        if hint? and hint != ""
            # TODO: Bessere Lösung
            hintIndex = -1
            for otherCell, index in @startingCells()
                if otherCell == cell
                    hintIndex = index
            return """<span class="current-hint-position">
                    #{@strings[direction]}, #{hintIndex + 1}
                </span>
                #{hint}
                """
        else
            return "<i>#{@strings.noHint}</i>"
    
    setCursor: (cursor, direction = @direction) ->
        @blur true
        
        @cursor = cursor
        @direction = direction
        
        @currentWord = @wordAfterCursor cursor, direction
        
        if @currentWord?
            for cell in @currentWord
                cell.classList.add('current-word')

        @cellAfter()?.classList.add "cursor-#{direction.before}"
        @cellBefore()?.classList.add "cursor-#{direction.after}"

        @currentHintDiv.innerHTML = @getHint @currentWord?[0], direction
        @currentHintDiv.hidden = false
        return
    
    focus: (cell, newDirection) ->
        cursor = @cursorAt cell
        unless newDirection?
            wordOnlyInOtherDirection = 
                @wordAfterCursor(cursor, @direction).length == 0 and
                @wordAfterCursor(cursor, @direction.other).length > 0
            hintStartOnlyInOtherDirection =
                not @hasHint(cell, @direction) and
                @hasHint(cell, @direction.other)
            
            if cell == @cellAfter() or
                    wordOnlyInOtherDirection or
                    hintStartOnlyInOtherDirection
                newDirection = @direction.other
            else
                newDirection = @direction
        
        @setCursor(cursor, newDirection)
        @secretInput.focus()
        return
    
    processInput: (e) ->
        if e.metaKey or e.ctrlKey
            return
            
        preventDefault = true
        preserveNumber = false
        
        if @permissibleLetters.indexOf(e.key) >= 0
            cell = @cellAfter()
            if (@isEntryCell cell) or @features.writeNewCells
                cell.textContent = e.key.toUpperCase()
                @advanceCursor()
        else if "0" <= e.key <= "9"
            preserveNumber = true
            @number = 0 if e.timeStamp - @numberTimeStamp > 1000
            @numberTimeStamp = e.timeStamp
            @number *= 10
            @number += parseInt(e.key)
            if (cell = @cellWithNumber(@number))?
                @focus cell
        else switch e.key
            when ' '
                cell = @cellAfter()
                if (@isEntryCell cell) or @features.writeNewCells
                    cell.innerHTML = "&nbsp;"
                    @advanceCursor()
            when 'ArrowRight'
                @setCursor(horizontal.advance @cursor)
            when 'ArrowLeft'
                @setCursor(horizontal.retrogress @cursor)
            when 'ArrowUp'
                @setCursor(vertical.retrogress @cursor)
            when 'ArrowDown'
                @setCursor(vertical.advance @cursor)
            when 'Tab'
                @setCursor(@cursor, @direction.other)
            when 'Backspace'
                cell = @cellBefore()
                if @isEntryCell cell
                    cell.innerHTML = '&nbsp;'
                    @retrogressCursor()
            when 'Enter'
                if @features.setBars
                    cell = @cellAfter()
                    attr = "data-hint-#{@direction}"
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
                    @advanceCursor()
                else
                    preventDefault = false
            else
                preventDefault = false
        
        @save()
        e.preventDefault() if preventDefault
        @number = 0 unless preserveNumber
        
    clear: ->
        for cell in @grid.querySelectorAll('td:not(:empty)')
            cell.innerHTML = "&nbsp;"
        try
            localStorage.removeItem("coffeeword-#{@container.id}-v1")
        catch
        return
    
    populateHints: ->
        for startingCell in @grid.querySelectorAll('td')
            if startingCell.getAttribute("data-hint-vertical") == '.'
                startingCell.setAttribute("data-hint-vertical", (cell.textContent for cell in @wordAfterCursor(@cursorAt(startingCell), vertical)).join '')
            if startingCell.getAttribute("data-hint-horizontal") == '.'
                startingCell.setAttribute("data-hint-horizontal", (cell.textContent for cell in @wordAfterCursor(@cursorAt(startingCell), horizontal)).join '')
        return
    
    saveV1: ->
        saveString = (for row in @grid.rows
            (cell.textContent for cell in row.cells).join ','
        ).join ';'
        try
            localStorage.setItem("coffeeword-#{@container.id}-v1", saveString)
        catch e
        saveString
    
    loadV1: (string) ->
        for rowString, row in string.split(';')
            for cellString, col in rowString.split(',')
                @cellAfter({row, col}).textContent = cellString
        return
    
    save: -> @saveV1()
    load: ->
        try
            params = new URL(location).searchParams
            if params.has("#{@container.id}-v1")
                saveString = params.get("#{@container.id}-v1")
            else
                saveString = localStorage.getItem("coffeeword-#{@container.id}-v1")
        catch
        if saveString?
            @loadV1(saveString)
    
    check: ->
        solutionHash = @grid.getAttribute('data-solution-hash-v1')
        return solutionHash == @currentHash()
    
    currentHash: ->
        hash @saveV1()
    
    createGrid: (empty = true) ->
        @blur()
        @grid.setAttribute('data-solution-hash-v1', @currentHash())
        if empty
            temp = @save()
            @clear()
        html = @grid.outerHTML
        if empty
            @loadV1(temp)
        return html

    @featuresFull:
        check: true
        clear: true
        print: true
        hintListing: true
        writeNewCells: false
        setBars: false
        createGrid: false
    
    @featuresCompact:
        check: true
        clear: true
        print: false
        hintListing: false
        writeNewCells: false
        setBars: false
        createGrid: false
    
    @featuresConstruction:
        check: false
        clear: true
        print: false
        hintListing: true
        writeNewCells: true
        setBars: true
        createGrid: true
    
    @languages:
        english: english
        german: german

window.Kreuzwort = Kreuzwort