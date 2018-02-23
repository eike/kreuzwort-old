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

window.kreuzwortAutoSetup = (container) =>
    grid = container.querySelector('table')
    elementAfterGrid = grid.nextElementSibling
    kreuzwort = new Kreuzwort(grid, container.id, Kreuzwort.featuresFull, container)
    # TODO: Better way to choose this automatically (HTML lang attribute?)
    localStrings = german
    
    currentClueDiv = document.createElement 'p'
    currentClueDiv.className = 'current-clue'
    currentClueDiv.hidden = true
    kreuzwort.addCallback('selectionChanged', (data) =>
        currentClueDiv.innerHTML = 
            if data.word?.clue?
                """<span class="current-word-position">
                        #{localStrings[data.word.direction]}, #{data.word.number}
                    </span>
                    #{data.word.clue} (#{data.word.length})
                    """
            else
                "<i>#{localStrings.noClue}</i>"
        console.log kreuzwort.currentCell
        for otherWord in kreuzwort.wordsAtCell kreuzwort.currentCell
            if otherWord != data.word and otherWord.clue?
                currentClueDiv.innerHTML += """<div class="other-clue">#{otherWord.clue}</div>"""
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
        
        kreuzwort.features = Kreuzwort.featuresConstruction
    
    if controlsDiv.hasChildNodes()
        container.insertBefore controlsDiv, elementAfterGrid
    
    unless container.classList.contains('compact')
        directions = [Kreuzwort.horizontal, Kreuzwort.vertical]
        for direction in directions
            head = document.createElement 'h2'
            head.textContent = localStrings[direction]
            container.insertBefore head, elementAfterGrid
            container.insertBefore (kreuzwort.clueListingForDirection direction), elementAfterGrid
    
    return kreuzwort

window.kreuzwortAutoInstances = []

window.addEventListener 'load', () =>
    document.querySelectorAll('.kreuzwort').forEach (container) =>
        kreuzwort = kreuzwortAutoSetup(container)
        kreuzwortAutoInstances.push kreuzwort
