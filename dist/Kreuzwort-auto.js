// Generated by CoffeeScript 2.0.2
(function() {
  var english, german, strings;

  strings = {
    checkSolution: 'checkSolution',
    solutionCorrect: 'solutionCorrect',
    solutionIncorrect: 'solutionIncorrect',
    reset: 'reset',
    resetConfirmation: 'resetConfirmation',
    horizontal: 'horizontal',
    vertical: 'vertical',
    showHTML: 'showHTML',
    copyHTML: 'copyHTML',
    hideHTML: 'hideHTML',
    noClue: 'noClue',
    print: 'print',
    printEmpty: 'printEmpty'
  };

  english = {
    checkSolution: 'Check Solution',
    solutionCorrect: 'The solution is correct.',
    solutionIncorrect: 'The crossword is incomplete or the solution is incorrect.',
    reset: 'Reset Crossword',
    resetConfirmation: 'Do you want to completely reset the crossword?',
    horizontal: 'Across',
    vertical: 'Down',
    showHTML: 'Show Grid HTML',
    copyHTML: 'Copy HTML to Clipboard',
    hideHTML: 'Hide Grid HTML',
    noClue: 'No clue in this direction',
    print: 'Print',
    printEmpty: 'Print Empty Grid'
  };

  german = {
    checkSolution: 'Lösung prüfen',
    solutionCorrect: 'Super, alles richtig.',
    solutionIncorrect: 'Leider ist noch nicht alles richtig.',
    reset: 'Alles löschen',
    resetConfirmation: 'Soll das Rätsel vollständig zurückgesetzt werden?',
    horizontal: 'Waagerecht',
    vertical: 'Senkrecht',
    showHTML: 'Gitter-HTML anzeigen',
    copyHTML: 'HTML in die Zwischenablage',
    hideHTML: 'Gitter-HTML ausblenden',
    noClue: 'Kein Hinweis in diese Richtung',
    print: 'Drucken',
    printEmpty: 'Leer drucken'
  };

  window.kreuzwortAutoSetup = (container) => {
    var checkButton, clearButton, controlsDiv, createButton, currentClueDiv, direction, directions, elementAfterGrid, grid, head, i, j, kreuzwort, len, len1, localStrings, printEmptyButton, printFullButton, ref, word;
    grid = container.querySelector('table');
    elementAfterGrid = grid.nextElementSibling;
    kreuzwort = new Kreuzwort(grid, container.id, Kreuzwort.featuresFull, container);
    // TODO: Better way to choose this automatically (HTML lang attribute?)
    localStrings = german;
    currentClueDiv = document.createElement('p');
    currentClueDiv.className = 'current-clue';
    currentClueDiv.hidden = true;
    kreuzwort.addCallback('selectionChanged', (data) => {
      var i, len, otherWord, ref, ref1;
      currentClueDiv.innerHTML = ((ref = data.word) != null ? ref.clue : void 0) != null ? `<span class="current-word-position">\n    ${localStrings[data.word.direction]}, ${data.word.number}\n</span>\n${data.word.clue} (${data.word.length})` : `<i>${localStrings.noClue}</i>`;
      console.log(kreuzwort.currentCell);
      ref1 = kreuzwort.wordsAtCell(kreuzwort.currentCell);
      for (i = 0, len = ref1.length; i < len; i++) {
        otherWord = ref1[i];
        if (otherWord !== data.word && (otherWord.clue != null)) {
          currentClueDiv.innerHTML += `<div class="other-clue">${otherWord.clue}</div>`;
        }
      }
      return currentClueDiv.hidden = false;
    });
    container.insertBefore(currentClueDiv, elementAfterGrid);
    ref = kreuzwort.words;
    
    // TODO: Auto-jumping might be annoying
    for (i = 0, len = ref.length; i < len; i++) {
      word = ref[i];
      word.addCallback('completed', () => {
        return kreuzwort.selectNextWord(1, true);
      });
    }
    controlsDiv = document.createElement('div');
    controlsDiv.className = 'controls';
    checkButton = document.createElement('button');
    checkButton.textContent = localStrings.checkSolution;
    checkButton.addEventListener('click', () => {
      if (kreuzwort.check()) {
        return alert(localStrings.solutionCorrect);
      } else {
        return alert(localStrings.solutionIncorrect);
      }
    });
    controlsDiv.append(checkButton);
    controlsDiv.append(' ');
    clearButton = document.createElement('button');
    clearButton.textContent = localStrings.reset;
    clearButton.addEventListener('click', () => {
      if (confirm(localStrings.resetConfirmation)) {
        return kreuzwort.clear();
      }
    });
    controlsDiv.append(clearButton);
    controlsDiv.append(' ');
    if (!container.classList.contains('compact')) {
      printEmptyButton = document.createElement('button');
      printEmptyButton.textContent = localStrings.printEmpty;
      printEmptyButton.addEventListener('click', () => {
        var temp;
        temp = kreuzwort.saveV1();
        kreuzwort.clear();
        window.print();
        return Promise.resolve().then(() => {
          kreuzwort.loadV1(temp);
          return kreuzwort.save();
        });
      });
      controlsDiv.append(printEmptyButton);
      controlsDiv.append(' ');
      printFullButton = document.createElement('button');
      printFullButton.textContent = localStrings.print;
      printFullButton.addEventListener('click', () => {
        return window.print();
      });
      controlsDiv.append(printFullButton);
      controlsDiv.append(' ');
    }
    if (container.classList.contains('construction')) {
      createButton = document.createElement('button');
      createButton.textContent = localStrings.copyHTML;
      createButton.addEventListener('click', () => {
        return toClipboard(kreuzwort.gridHTML());
      });
      controlsDiv.append(createButton);
      controlsDiv.append(' ');
      kreuzwort.features = Kreuzwort.featuresConstruction;
    }
    if (controlsDiv.hasChildNodes()) {
      container.insertBefore(controlsDiv, elementAfterGrid);
    }
    if (!container.classList.contains('compact')) {
      directions = [Kreuzwort.horizontal, Kreuzwort.vertical];
      for (j = 0, len1 = directions.length; j < len1; j++) {
        direction = directions[j];
        head = document.createElement('h2');
        head.textContent = localStrings[direction];
        container.insertBefore(head, elementAfterGrid);
        container.insertBefore(kreuzwort.clueListingForDirection(direction), elementAfterGrid);
      }
    }
    return kreuzwort;
  };

  window.addEventListener('load', () => {
    return document.querySelectorAll('.kreuzwort').forEach(kreuzwortAutoSetup);
  });

}).call(this);
