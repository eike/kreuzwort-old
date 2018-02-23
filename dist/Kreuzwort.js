// Generated by CoffeeScript 2.0.2
(function() {
  // Kreuzwort.coffee

  // Copyright 2018 Eike Schulte

  // Licensed under the Apache License, Version 2.0 (the "License");
  // you may not use this file except in compliance with the License.
  // You may obtain a copy of the License at

  //     http://www.apache.org/licenses/LICENSE-2.0

  // Unless required by applicable law or agreed to in writing, software
  // distributed under the License is distributed on an "AS IS" BASIS,
  // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  // See the License for the specific language governing permissions and
  // limitations under the License.
  var Kreuzwort, Word, cellMatrixToWordList, compareWordsDomOrder, constFalse, createSecretInput, hash, standardBlockTest, standardInputCallback, standardLetters, toClipboard, wordStartsToRegExp;

  Word = class Word {
    constructor(cells1, direction1) {
      this.cells = cells1;
      this.direction = direction1;
      this.callbacks = {
        changed: [],
        completed: [],
        selected: [],
        unselected: []
      };
    }

    addCallback(event, callback) {
      return this.callbacks[event].push(callback);
    }

    trigger(event, data) {
      var callback, k, len, ref, results;
      ref = this.callbacks[event];
      results = [];
      for (k = 0, len = ref.length; k < len; k++) {
        callback = ref[k];
        results.push(callback(data, this));
      }
      return results;
    }

    toString() {
      var cell, unsolved;
      return ((function() {
        var k, len, ref, results;
        ref = this.cells;
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          cell = ref[k];
          if (cell.innerHTML === '&nbsp;') {
            results.push('␣');
          } else {
            unsolved = false;
            results.push(cell.innerHTML);
          }
        }
        return results;
      }).call(this)).join('');
    }

    addClass(className = 'current-word') {
      var cell, k, len, ref;
      ref = this.cells;
      for (k = 0, len = ref.length; k < len; k++) {
        cell = ref[k];
        cell.classList.add(className);
      }
    }

    removeClass(className = 'current-word') {
      var cell, k, len, ref;
      ref = this.cells;
      for (k = 0, len = ref.length; k < len; k++) {
        cell = ref[k];
        cell.classList.remove(className);
      }
    }

  };

  Object.defineProperties(Word.prototype, {
    clue: {
      get: function() {
        var clue;
        clue = this.startingCell.getAttribute(`data-clue-${this.direction}`);
        if ((clue != null) && clue !== "") {
          return clue;
        } else {
          return void 0;
        }
      },
      set: function(clue) {
        if (clue == null) {
          clue = '';
        }
        return this.startingCell.setAttribute(`data-clue-${this.direction}`, clue);
      }
    },
    explanation: {
      get: function() {
        var explanation;
        explanation = this.startingCell.getAttribute(`data-explanation-${this.direction}`);
        if ((explanation != null) && explanation !== "") {
          return explanation;
        } else {
          return void 0;
        }
      },
      set: function(explanation) {
        return this.startingCell.setAttribute(`data-explanation-${this.direction}`, explanation);
      }
    },
    explicitNumber: {
      get: function() {
        return this.startingCell.getAttribute('data-explicit-number');
      }
    },
    firstEmptyPosition: {
      get: function() {
        var cell, index, k, len, ref;
        ref = this.cells;
        for (index = k = 0, len = ref.length; k < len; index = ++k) {
          cell = ref[index];
          if (cell.textContent === ' ') {
            return index;
          }
        }
        return this.length;
      }
    },
    isComplete: {
      get: function() {
        var cell, k, len, ref;
        ref = this.cells;
        for (k = 0, len = ref.length; k < len; k++) {
          cell = ref[k];
          if (cell.textContent === ' ') {
            return false;
          }
        }
        return true;
      }
    },
    isEmpty: {
      get: function() {
        var cell, k, len, ref;
        ref = this.cells;
        for (k = 0, len = ref.length; k < len; k++) {
          cell = ref[k];
          if (cell.textContent !== ' ') {
            return false;
          }
        }
        return true;
      }
    },
    length: {
      get: function() {
        return this.cells.length;
      }
    },
    number: {
      get: function() {
        return this.startingCell.getAttribute('data-cell-number');
      },
      set: function(number) {
        return this.startingCell.setAttribute("data-cell-number", number);
      }
    },
    startingCell: {
      get: function() {
        return this.cells[0];
      }
    }
  });

  Kreuzwort = (function() {
    class Kreuzwort {
      constructor(grid1, saveId, features = Kreuzwort.featuresFull, hiddenContainer = document.body) {
        var cell, cellWords, elementAfterGrid, k, l, len, len1, len2, o, ref, ref1, ref2, word;
        this.grid = grid1;
        this.saveId = saveId;
        this.features = features;
        this.callbacks = {
          changed: [],
          input: [standardInputCallback],
          save: [this.saveV2.bind(this)],
          selectionChanged: []
        };
        this.cellMatrix = tableCellMatrix(this.grid);
        //@previousInput = createSecretInput()
        //@previousInput.onfocus = () =>
        //    @retrogressCursor()
        //    @secretInput.focus()
        //document.body.appendChild @previousInput
        this.secretInput = createSecretInput();
        // TODO: When @secretInput looses focus, maybe grey-out current word
        hiddenContainer.appendChild(this.secretInput);
        this.cursorSpan = document.createElement('span');
        this.cursorSpan.className = 'cursor';
        this.cursorSpan.style['position'] = 'absolute';
        hiddenContainer.appendChild(this.cursorSpan);
        ref = this.grid.querySelectorAll('td');
        
        //@nextInput = createSecretInput()
        //@nextInput.onfocus = () =>
        //    @advanceCursor()
        //    @secretInput.focus()
        //document.body.appendChild @nextInput
        for (k = 0, len = ref.length; k < len; k++) {
          cell = ref[k];
          cell.addEventListener('click', (event) => {
            if (this.isEntryCell(event.target)) {
              this.repositionSecretInputs();
              return this.focus(event.target);
            }
          });
        }
        this.words = cellMatrixToWordList(this.cellMatrix, Kreuzwort.horizontal, (cell) => {
          return cell.hasAttribute("data-clue-horizontal");
        }).concat(cellMatrixToWordList(this.cellMatrix, Kreuzwort.vertical, (cell) => {
          return cell.hasAttribute("data-clue-vertical");
        }));
        this.numberWords();
        this._wordsAtCell = new Map();
        ref1 = this.words;
        for (l = 0, len1 = ref1.length; l < len1; l++) {
          word = ref1[l];
          ref2 = word.cells;
          for (o = 0, len2 = ref2.length; o < len2; o++) {
            cell = ref2[o];
            cellWords = this.wordsAtCell(cell);
            cellWords.push(word);
            this._wordsAtCell.set(cell, cellWords);
          }
        }
        elementAfterGrid = this.grid.nextSibling;
        this.secretInput.onkeydown = (e) => {
          return this.processInput(e);
        };
        this.repositionSecretInputs();
        this.number = 0;
        this.numberTimeStamp = 0;
        this.load();
      }

      addCallback(event, callback) {
        return this.callbacks[event].push(callback);
      }

      trigger(event, data) {
        var callback, k, len, ref, results;
        ref = this.callbacks[event];
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          callback = ref[k];
          results.push(callback(data, this));
        }
        return results;
      }

      selectNextWord(step = 1, skipComplete = false) {
        var index, startingIndex, word;
        startingIndex = this.words.indexOf(this.currentWord);
        if (startingIndex === -1) {
          return;
        }
        index = ((startingIndex + step) % this.words.length + this.words.length) % this.words.length;
        while (index !== startingIndex) {
          word = this.words[index];
          if ((word.clue != null) && (!skipComplete || !word.isComplete)) {
            this.currentWord = word;
            return;
          }
          index = ((index + step) % this.words.length + this.words.length) % this.words.length;
        }
        if (skipComplete) {
          
          // If no un-completed word exists, select the next clued word
          this.selectNextWord(step, false);
        }
      }

      explicitNumbers() {
        var k, len, ref, results, td;
        ref = this.grid.querySelectorAll('td[data-explicit-number]');
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          td = ref[k];
          results.push(td.getAttribute('data-explicit-number'));
        }
        return results;
      }

      unnumberCells() {
        var k, len, ref, results, td;
        ref = this.grid.querySelectorAll('td[data-cell-number]');
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          td = ref[k];
          results.push(td.removeAttribute('data-cell-number'));
        }
        return results;
      }

      
      // TODO: A more elegant way of setting the standard for numbering?
      numberWords(words = this.words.filter((word) => {
          return word.clue != null;
        })) {
        var cellNumberGenerator, k, l, len, len1, ref, ref1, results, td, word;
        cellNumberGenerator = (function*(exclude) {
          var num, number;
          num = 0;
          while (true) {
            num++;
            number = num.toString();
            if (!(exclude.indexOf(number) >= 0)) {
              yield number;
            }
          }
        })(this.explicitNumbers());
        ref = this.grid.querySelectorAll('td[data-explicit-number]');
        for (k = 0, len = ref.length; k < len; k++) {
          td = ref[k];
          td.setAttribute('data-cell-number', td.getAttribute('data-explicit-number'));
        }
        ref1 = words.sort(compareWordsDomOrder);
        results = [];
        for (l = 0, len1 = ref1.length; l < len1; l++) {
          word = ref1[l];
          if (word.number == null) {
            results.push(word.number = cellNumberGenerator.next().value);
          } else {
            results.push(void 0);
          }
        }
        return results;
      }

      renumber() {
        this.unnumberCells();
        return this.numberWords();
      }

      cellWithNumber(number) {
        return this.grid.querySelector(`td[data-cell-number='${number}']`);
      }

      wordsAtCell(cell) {
        return this._wordsAtCell.get(cell) || [];
      }

      repositionSecretInputs() {
        this.secretInput.style['top'] = `${this.grid.offsetTop}px`;
        return this.secretInput.style['height'] = `${this.grid.offsetHeight}px`;
      }

      cellAfter(cursor) {
        var ref;
        return (ref = this.cellMatrix[cursor.row]) != null ? ref[cursor.col] : void 0;
      }

      cellBefore(cursor, direction) {
        return this.cellAfter(direction.retrogress(cursor));
      }

      isEntryCell(cell) {
        return (cell != null) && cell.textContent !== "";
      }

      focus(cell) {
        var newWord, words, wordsStartingHere, wordsWithClues;
        words = this.wordsAtCell(cell);
        if (cell === this.currentCell) {
          newWord = words[(words.indexOf(this.currentWord) + 1) % words.length];
        } else {
          wordsWithClues = words.filter((word) => {
            return word.clue != null;
          });
          wordsStartingHere = wordsWithClues.filter((word) => {
            return word.startingCell === cell;
          });
          newWord = (wordsStartingHere.concat(wordsWithClues, words))[0];
        }
        this.currentWord = newWord;
        this.positionInWord = this.currentWord.cells.indexOf(cell);
        this.secretInput.focus();
      }

      cellChanged(cell) {
        var k, len, ref, results, word;
        this.trigger('changed', {
          cell: cell
        });
        ref = this.wordsAtCell(cell);
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          word = ref[k];
          results.push(word.trigger('changed'));
        }
        return results;
      }

      write(content) {
        var cell;
        // TODO: It might be nice to automatically grow the grid when a new cell is written at the end
        cell = this.currentCell;
        if ((this.isEntryCell(cell)) || (this.features.writeNewCells && (cell != null))) {
          cell.textContent = content;
          this.cellChanged(cell);
          this.positionInWord += 1;
          if (this.currentWord.length === this.positionInWord) {
            this.currentWord.trigger('completed');
          }
          return true;
        } else {
          return false;
        }
      }

      setBar() {
        var direction, index, nextPosition, nextWord, postWord, preWord;
        direction = this.currentWord.direction;
        index = this.words.indexOf(this.currentWord);
        this.words.splice(index, 1);
        preWord = new Word(this.currentWord.cells.slice(0, this.positionInWord), direction);
        postWord = new Word(this.currentWord.cells.slice(this.positionInWord), direction);
        if (preWord.length > 0) {
          this.words.push(preWord);
          nextWord = preWord;
          nextPosition = preWord.length;
        }
        if (postWord.length > 0) {
          postWord.clue = ".";
          this.words.push(postWord);
          nextWord = postWord;
          nextPosition = 0;
        }
        this.words.sort(compareWordsDomOrder); // TODO: Change sort to clue-order
        this.renumber();
        // Do this after renumbering so the right number is shown below the crossword immediately
        this.currentWord = nextWord;
        this.positionInWord = nextPosition;
      }

      processInput(e) {
        var callbackResult, cell, entry, inputProcessed, k, l, len, len1, preserveNumber, ref, ref1;
        if (e.metaKey || e.ctrlKey) {
          return;
        }
        e.preventDefault();
        preserveNumber = false;
        inputProcessed = false;
        ref = this.trigger('input', {
          key: e.key
        }).reverse();
        for (k = 0, len = ref.length; k < len; k++) {
          callbackResult = ref[k];
          if (callbackResult != null) {
            inputProcessed = true;
            for (l = 0, len1 = callbackResult.length; l < len1; l++) {
              entry = callbackResult[l];
              this.write(entry);
            }
            break;
          }
        }
        if (!inputProcessed) {
          if (("0" <= (ref1 = e.key) && ref1 <= "9")) {
            preserveNumber = true;
            if (e.timeStamp - this.numberTimeStamp > 1000) {
              this.number = 0;
            }
            this.numberTimeStamp = e.timeStamp;
            this.number *= 10;
            this.number += parseInt(e.key);
            if ((cell = this.cellWithNumber(this.number)) != null) {
              this.focus(cell);
            }
          } else {
            switch (e.key) {
              case ' ':
                this.focus(this.currentCell);
                break;
              case 'ArrowRight':
                console.log('TODO: Arrows');
                break;
              case 'ArrowLeft':
                console.log('TODO: Arrows');
                break;
              case 'ArrowUp':
                console.log('TODO: Arrows');
                break;
              case 'ArrowDown':
                console.log('TODO: Arrows');
                break;
              case 'Tab':
                if (e.shiftKey) {
                  this.selectNextWord(-1);
                } else {
                  this.selectNextWord(1, true);
                }
                break;
              case 'Backspace':
                cell = this.currentWord.cells[this.positionInWord - 1];
                if (this.isEntryCell(cell)) {
                  cell.innerHTML = '&nbsp;';
                  this.cellChanged(cell);
                  this.positionInWord -= 1;
                }
                break;
              case '|':
                if (this.features.setBars) {
                  this.setBar();
                }
                break;
              case 'Delete':
                if (this.features.writeNewCells) {
                  this.write('');
                }
            }
          }
        }
        this.save();
        if (!preserveNumber) {
          return this.number = 0;
        }
      }

      clear(clearStorage = true) {
        var cell, k, len, ref;
        ref = this.grid.querySelectorAll('td:not(:empty)');
        for (k = 0, len = ref.length; k < len; k++) {
          cell = ref[k];
          cell.innerHTML = "&nbsp;";
        }
        if (clearStorage) {
          try {
            localStorage.removeItem(`coffeeword-${this.saveId}-v1`);
          } catch (error) {

          }
        }
      }

      populateClues() {
        var k, len, ref, word;
        ref = this.words;
        for (k = 0, len = ref.length; k < len; k++) {
          word = ref[k];
          if (word.clue === '.') {
            word.clue = word.toString();
          }
        }
      }

      saveV1() {
        var cell, e, row, saveString;
        saveString = ((function() {
          var k, len, ref, results;
          ref = this.grid.rows;
          results = [];
          for (k = 0, len = ref.length; k < len; k++) {
            row = ref[k];
            results.push(((function() {
              var l, len1, ref1, results1;
              ref1 = row.cells;
              results1 = [];
              for (l = 0, len1 = ref1.length; l < len1; l++) {
                cell = ref1[l];
                results1.push(cell.textContent);
              }
              return results1;
            })()).join(','));
          }
          return results;
        }).call(this)).join(';');
        try {
          localStorage.setItem(`coffeeword-${this.saveId}-v1`, saveString);
        } catch (error) {
          e = error;
        }
        return saveString;
      }

      saveV2() {
        var cell, row, saveString;
        saveString = ((function() {
          var k, len, ref, results;
          ref = this.grid.rows;
          results = [];
          for (k = 0, len = ref.length; k < len; k++) {
            row = ref[k];
            results.push(((function() {
              var l, len1, ref1, results1;
              ref1 = row.cells;
              results1 = [];
              for (l = 0, len1 = ref1.length; l < len1; l++) {
                cell = ref1[l];
                switch (cell.textContent) {
                  case ' ':
                    results1.push('_');
                    break;
                  case '':
                    results1.push('.');
                    break;
                  default:
                    results1.push(cell.textContent);
                }
              }
              return results1;
            })()).join(''));
          }
          return results;
        }).call(this)).join('-');
        if (this.saveId != null) {
          try {
            localStorage.setItem(`kreuzwort-${this.saveId}-v2`, saveString);
          } catch (error) {

          }
        }
        return saveString;
      }

      loadV1(string) {
        var cellString, col, k, l, len, len1, ref, ref1, row, rowString;
        ref = string.split(';');
        for (row = k = 0, len = ref.length; k < len; row = ++k) {
          rowString = ref[row];
          ref1 = rowString.split(',');
          for (col = l = 0, len1 = ref1.length; l < len1; col = ++l) {
            cellString = ref1[col];
            this.cellAfter({row, col}).textContent = cellString;
          }
        }
      }

      loadV2(string) {
        var cellString, col, k, l, len, len1, ref, ref1, row, rowString;
        ref = string.split('-');
        for (row = k = 0, len = ref.length; k < len; row = ++k) {
          rowString = ref[row];
          ref1 = rowString.split('');
          for (col = l = 0, len1 = ref1.length; l < len1; col = ++l) {
            cellString = ref1[col];
            this.cellAfter({row, col}).textContent = (function() {
              switch (cellString) {
                case '_':
                  return ' ';
                case '.':
                  return '';
                default:
                  return cellString;
              }
            })();
          }
        }
      }

      save() {
        return this.trigger('save');
      }

      load() {
        var params, saveString;
        if (this.saveId == null) {
          return;
        }
        try {
          params = new URL(location).searchParams;
          if (params.has(`${this.saveId}-v2`)) {
            return this.loadV2(params.get(`${this.saveId}-v2`));
          } else if (params.has(`${this.saveId}-v1`)) {
            return this.loadV1(params.get(`${this.saveId}-v1`));
          } else if (saveString = localStorage.getItem(`kreuzwort-${this.saveId}-v2`)) {
            return this.loadV2(saveString);
          } else {
            return this.loadV1(localStorage.getItem(`coffeeword-${this.saveId}-v1`));
          }
        } catch (error) {

        }
      }

      // I don’t think we can do anything useful when local storage does not work
      progressURL() {
        var url;
        url = new URL(location);
        url.searchParams.set(`${this.saveId}-v2`, this.saveV2());
        return url;
      }

      check() {
        var solutionHash;
        solutionHash = this.grid.getAttribute('data-solution-hash-v1');
        return solutionHash === this.currentHash();
      }

      currentHash() {
        return hash(this.saveV1());
      }

      gridHTML() {
        var cell, html, k, len, ref, temp, word;
        word = this.currentWord;
        this.currentWord = null;
        this.grid.setAttribute('data-solution-hash-v1', this.currentHash());
        this.unnumberCells();
        ref = this.grid.querySelectorAll("td[class='']");
        for (k = 0, len = ref.length; k < len; k++) {
          cell = ref[k];
          cell.removeAttribute('class');
        }
        this.populateClues();
        temp = this.saveV1();
        this.clear(false);
        html = this.grid.outerHTML;
        this.loadV1(temp);
        this.numberWords();
        this.currentWord = word;
        return html;
      }

      cellNumbersForDirection(direction) {
        var k, len, ref, results, word;
        ref = this.words.filter((word) => {
          return word.direction === direction;
        });
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          word = ref[k];
          if (word.clue != null) {
            results.push(word.number);
          }
        }
        return results;
      }

      fillCluesFromArrayForDirection(clues, direction) {
        var clue, index, k, len, ref, results, words;
        words = this.words.filter((word) => {
          return (word.clue != null) && word.direction === direction;
        });
        results = [];
        for (index = k = 0, len = clues.length; k < len; index = ++k) {
          clue = clues[index];
          results.push((ref = words[index]) != null ? ref.clue = clue : void 0);
        }
        return results;
      }

      fillCluesFromTextForDirection(text, direction) {
        var cellNumbers, clues, re;
        cellNumbers = this.cellNumbersForDirection(direction);
        re = wordStartsToRegExp(cellNumbers);
        clues = re.exec(text).splice(1);
        return this.fillCluesFromArrayForDirection(clues, direction);
      }

      clueWordsAtLeastLong(n) {
        var k, len, ref, word;
        ref = this.words;
        for (k = 0, len = ref.length; k < len; k++) {
          word = ref[k];
          if (word.length >= n) {
            word.clue = '.';
          }
        }
        return this.numberWords();
      }

      clueListingForDirection(direction) {
        var fn, fn1, fn2, k, len, li, ol, ref, word;
        ol = document.createElement('ol');
        ref = this.words;
        fn = (li) => {
          word.addCallback('selected', () => {
            return li.classList.add('current-clue');
          });
          return word.addCallback('unselected', () => {
            return li.classList.remove('current-clue');
          });
        };
        fn1 = (li) => {
          return word.addCallback('changed', (_, word) => {
            if (word.isComplete) {
              li.classList.add('complete');
            } else {
              li.classList.remove('complete');
            }
            if (word.isEmpty) {
              return li.removeAttribute('data-partial-solution');
            } else {
              return li.setAttribute('data-partial-solution', word.toString());
            }
          });
        };
        fn2 = (word) => {
          return li.onclick = () => {
            this.currentWord = word;
            return this.secretInput.focus();
          };
        };
        for (k = 0, len = ref.length; k < len; k++) {
          word = ref[k];
          if (!(word.direction === direction)) {
            continue;
          }
          if (word.clue == null) {
            continue;
          }
          li = document.createElement('li');
          li.value = word.number;
          fn(li);
          li.innerHTML = word.clue;
          li.setAttribute('data-enumeration', word.length);
          if (!word.isEmpty) {
            li.setAttribute('data-partial-solution', word.toString());
          }
          if (word.isComplete) {
            li.classList.add('complete');
          }
          fn1(li);
          fn2(word);
          ol.appendChild(li);
        }
        return ol;
      }

    };

    Kreuzwort.featuresFull = {
      writeNewCells: false,
      setBars: false
    };

    Kreuzwort.featuresConstruction = {
      writeNewCells: true,
      setBars: true
    };

    Kreuzwort.horizontal = {
      toString: () => {
        return "horizontal";
      },
      advance: (cursor) => {
        if (cursor != null) {
          return {
            row: cursor.row,
            col: cursor.col + 1
          };
        } else {
          return null;
        }
      },
      retrogress: (cursor) => {
        if (cursor != null) {
          return {
            row: cursor.row,
            col: cursor.col - 1
          };
        } else {
          return null;
        }
      },
      before: 'left',
      after: 'right',
      other: null
    };

    Kreuzwort.vertical = {
      toString: () => {
        return "vertical";
      },
      advance: (cursor) => {
        if (cursor != null) {
          return {
            row: cursor.row + 1,
            col: cursor.col
          };
        } else {
          return null;
        }
      },
      retrogress: (cursor) => {
        if (cursor != null) {
          return {
            row: cursor.row - 1,
            col: cursor.col
          };
        } else {
          return null;
        }
      },
      before: 'top',
      after: 'bottom',
      other: Kreuzwort.horizontal
    };

    return Kreuzwort;

  })();

  Kreuzwort.horizontal.other = Kreuzwort.vertical;

  Object.defineProperties(Kreuzwort.prototype, {
    currentCell: {
      get: function() {
        var ref;
        return (ref = this.currentWord) != null ? ref.cells[this.positionInWord] : void 0;
      }
    },
    currentWord: {
      get: function() {
        return this._currentWord;
      },
      set: function(newWord) {
        var ref, ref1, ref2, ref3, ref4, ref5;
        if (newWord !== this._currentWord) {
          if ((ref = this._currentWord) != null) {
            ref.removeClass();
          }
          if ((ref1 = this._currentWord) != null) {
            ref1.trigger('unselected');
          }
          this._currentWord = newWord;
          if (((ref2 = this._currentWord) != null ? ref2.clue : void 0) != null) {
            if ((ref3 = this._currentWord) != null) {
              ref3.addClass();
            }
          }
          if ((ref4 = this._currentWord) != null) {
            ref4.trigger('selected');
          }
          return this.positionInWord = (ref5 = this._currentWord) != null ? ref5.firstEmptyPosition : void 0;
        }
      }
    },
    numberOfBlacks: {
      get: function() {
        return this.grid.querySelectorAll('td:empty').length;
      }
    },
    numberOfClues: {
      get: function() {
        return this.words.filter((word) => {
          return word.clue != null;
        }).length;
      }
    },
    numberOfWhites: {
      get: function() {
        return this.grid.querySelectorAll('td:not(:empty)').length;
      }
    },
    positionInWord: {
      get: function() {
        return this._positionInWord;
      },
      set: function(newPosition) {
        var cell, left, top;
        // TODO: I’m still not sure whether the cursor should be a class on the current cell or a moving span
        // Pros of the class
        // - cursor updates automatically when window resizes
        // - more controll for the designer
        // - less code here
        // Pros of the moving span
        // - easier support for cells that are not 1x1
        // - less work for the designer
        // - using classes for everything might strain the ::before and ::after pseudo elements (cell-number, cursor and markings for hyphens/spaces would be to much)
        this._positionInWord = newPosition;
        this.trigger('selectionChanged', {
          word: this._currentWord,
          position: this._positionInWord
        });
        if ((0 <= newPosition && newPosition < this.currentWord.length)) {
          cell = this.currentWord.cells[newPosition];
          top = cell.offsetTop + 1;
          left = cell.offsetLeft + 1;
        } else if (newPosition === this.currentWord.length) {
          cell = this.currentWord.cells[newPosition - 1];
          top = cell.offsetTop + (this.currentWord.direction === Kreuzwort.vertical ? cell.offsetHeight - 3 : 1);
          left = cell.offsetLeft + (this.currentWord.direction === Kreuzwort.horizontal ? cell.offsetWidth - 3 : 1);
        }
        this.cursorSpan.style['top'] = `${top}px`;
        this.cursorSpan.style['left'] = `${left}px`;
        if (this.currentWord.direction === Kreuzwort.horizontal) {
          this.cursorSpan.style['width'] = "3px";
          return this.cursorSpan.style['height'] = `${cell.offsetHeight - 1}px`;
        } else if (this.currentWord.direction === Kreuzwort.vertical) {
          this.cursorSpan.style['width'] = `${cell.offsetWidth - 1}px`;
          return this.cursorSpan.style['height'] = "3px";
        }
      }
    }
  });

  hash = (string) => {
    var c, char, h, k, len;
    h = 0;
    if (string.length === 0) {
      return h;
    }
    for (k = 0, len = string.length; k < len; k++) {
      char = string[k];
      c = char.charCodeAt();
      h = ((h << 5) - h) + c;
      h = h & h; // Convert to 32bit integer
    }
    return h.toString();
  };

  toClipboard = (string) => {
    var textarea;
    textarea = document.createElement('textarea');
    textarea.value = string;
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    return document.body.removeChild(textarea);
  };

  createSecretInput = function(outline) {
    var secretInput;
    secretInput = document.createElement('input');
    secretInput.style['position'] = 'absolute';
    secretInput.style['margin'] = '0';
    secretInput.style['padding'] = '0';
    secretInput.style['border'] = 'none';
    secretInput.style['outline'] = `1px solid ${outline}`;
    secretInput.style['left'] = '-10000px';
    return secretInput;
  };

  // TODO: This might fail if words start on cells that are not 1x1.
  compareWordsDomOrder = function(wordA, wordB) {
    var cellA, cellB, rowDiff;
    cellA = wordA.startingCell;
    cellB = wordB.startingCell;
    rowDiff = cellA.parentElement.rowIndex - cellB.parentElement.rowIndex;
    if (rowDiff !== 0) {
      return rowDiff;
    } else {
      return cellA.cellIndex - cellB.cellIndex;
    }
  };

  standardLetters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");

  standardInputCallback = function(e) {
    if ((standardLetters.indexOf(e.key)) >= 0) {
      return [e.key.toUpperCase()];
    } else {
      return null;
    }
  };

  wordStartsToRegExp = function(starts) {
    return new RegExp((starts.join('([^]*)')) + '([^].*)');
  };

  window.fromGrid = function(grid) {
    var cell, cells, colNum, k, l, len, len1, prevCell, prevRow, row, rows, table, td, tr;
    table = document.createElement('table');
    rows = grid.trim().split('\n');
    prevRow = [];
    for (k = 0, len = rows.length; k < len; k++) {
      row = rows[k];
      tr = document.createElement('tr');
      cells = row.trim().split('');
      prevCell = '.';
      for (colNum = l = 0, len1 = cells.length; l < len1; colNum = ++l) {
        cell = cells[colNum];
        td = document.createElement('td');
        if (cell === '.') {
          td.innerHTML = '';
        } else if (cell === 'X') {
          td.innerHTML = '&nbsp;';
        } else {
          td.innerHTML = cell;
        }
        tr.appendChild(td);
        prevCell = cell;
      }
      table.appendChild(tr);
      prevRow = row;
    }
    return table;
  };

  window.tableCellMatrix = function(table) {
    var cell, col, i, j, k, l, len, len1, m, o, p, ref, ref1, ref2, ref3, row, rowElem;
    m = [];
    ref = table.rows;
    for (row = k = 0, len = ref.length; k < len; row = ++k) {
      rowElem = ref[row];
      col = 0;
      if (m[row] == null) {
        m[row] = [];
      }
      ref1 = rowElem.cells;
      for (l = 0, len1 = ref1.length; l < len1; l++) {
        cell = ref1[l];
        while (m[row][col] != null) {
          col++;
        }
        for (i = o = 0, ref2 = cell.rowSpan || 1; 0 <= ref2 ? o < ref2 : o > ref2; i = 0 <= ref2 ? ++o : --o) {
          for (j = p = 0, ref3 = cell.colSpan || 1; 0 <= ref3 ? p < ref3 : p > ref3; j = 0 <= ref3 ? ++p : --p) {
            if (m[row + i] == null) {
              m[row + i] = [];
            }
            m[row + i][col + j] = cell;
          }
        }
      }
    }
    return m;
  };

  constFalse = function() {
    return false;
  };

  standardBlockTest = function(cell) {
    return cell.textContent === '';
  };

  cellMatrixToWordList = function(matrix, direction, hasBarBefore = constFalse, isBlock = standardBlockTest) {
    var currentCell, currentCells, currentCursor, isInBounds, lineStart, pushWord, words;
    words = [];
    currentCells = [];
    isInBounds = (cursor) => {
      return cursor.row < matrix.length && cursor.col < matrix[0].length;
    };
    pushWord = () => {
      if (currentCells.length > 0) {
        words.push(new Word(currentCells, direction));
        return currentCells = [];
      }
    };
    lineStart = {
      row: 0,
      col: 0
    };
    while (isInBounds(lineStart)) {
      currentCursor = lineStart;
      while (isInBounds(currentCursor)) {
        currentCell = matrix[currentCursor.row][currentCursor.col];
        if (isBlock(currentCell) || hasBarBefore(currentCell)) {
          pushWord();
        }
        if (!isBlock(currentCell) && (currentCells[currentCells.length - 1] !== currentCell)) {
          currentCells.push(currentCell);
        }
        currentCursor = direction.advance(currentCursor);
      }
      pushWord();
      lineStart = direction.other.advance(lineStart);
    }
    words.sort(compareWordsDomOrder);
    return words;
  };

  window.Kreuzwort = Kreuzwort;

}).call(this);
