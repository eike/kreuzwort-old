# kreuzwort.coffee

kreuzwort.coffee is a Coffeescript for displaying beautiful and interactive crosswords on webpages. See it in action here: [kifu.eu](http://kifu.eu) (Crosswords in German)

## Features

* Easy-to-use cursor-based crossword navigation
* Pure coffeescript or javascript, no libraries or frameworks required
* Arbitrary crossword shapes (no non-square cells, though)
* Support for barred and boxed grids
* Saves solving progress in local storage
* Relativly light-weight markup

## User controls

* Clicking on a cell sets the cursor in front of that cell and changes direction if sensible
* Typing places or replaces text, Backspace for deleting backwards
* Space or clicking the cell behind the cursor changes writing direction
* Tab jumps to the next word
* Enter a number to jump to the corresponding starting cell
* Click on a hint to select the corresponding cells in the grid

## Using the script

The basic setup is as follows. See the examples folder for ideas.

1.  Embed the script in your page, e.g.

        <script type="javascript" src="kreuzwort.js"></script>

2.  Prepare your grid: kreuzwort.coffee expects a `table` representing the grid. In this table:
    - Non-empty cells represent input cells, completely empty cells are blocks.
    - Clues can be placed by setting the `data-clue-vertical` and/or `data-clue-horizontal` attributes of the starting cell. To create a bar without giving a clue leave the value of the attribute blank. These empty clues will not show up in the hint listing and the corresponding cell will not be numbered (unless a clue is given in the other direction). The values of the clue attributes are used as innerHTML, so you can add HTML tags for special styling, (but beware of XSS if users can generate clues for others to see!)

3.  The easiest way to connect the Kreuzwort script to your grid is by placing your grid in some container with a class of `kreuzwort`. On page load, the script will turn the first table in each grid into an interactive crossword. If you want a more compact version without a listing of all the clues, add the class `compact` as well. If the container has class `construction`, bars can be set by typing '|' and blocks can be set by typing Delete or '.'. If an `id` is present on the container, it will be used as an identifier for the crossword when preserving its state (so using the same id on different crosswords will lead them to share their state, which you probably don’t want).
    
    The following is out of date: If you want additional control, you can also call the constructor directly:
    
        kreuzwort = new Kreuzwort(grid, saveId)
    
    `grid` should be the `table` element representing the crossword grid. `saveId` should be a string that is used when the crossword saves the progress in local storage. It should be unique for each crossword on your site. Using the same saveId on different crosswords will lead to them sharing the same state. No elements will be added to your page automatically, except for hidden inputs. Look at the function `kreuzwortAutoSetup` at the end of the script to get an idea of how to create controls and clue listings yourself.
    
4.  Add a stylesheet. The script will add the class `current-word` to all cells of the currently selected word. Also, a `span` with a class of `cursor` will be added to represent the cursor. You should add a background color to make the cursor visible. 
    
    If you use the auto-setup, the following elements will additionally be added below the grid:
    - a paragraph `current-clue` containing a span with class `current-word-position` for the position of the word (i.e. 'Down, 7') and the hint
    - a div `controls` containing the buttons for checking, clearing, printing etc.
    - headings h2 and ordered lists of hints for Across and Down. The list items have attributes `data-enumeration` and `data-partial-solution` reflecting the length of the entry and a string representation of its state (unless it is completely empty). Completed (not necessarily correct) entries also get the class `completed`. The clue for the currently selected word gets the class `current-clue`.

See also in the examples folder.

### Tips

- Kreuzwort.coffee adds cell numbers to the cells in form of the `data-cell-number` attributes. They are not visible by default, but you can show them with CSS ::before pseudo elements. The numbering is sequential, but you can also add `data-explicit-number` attributes to force cells to have a specific numbers. These cells and numbers will be omitted in the automatic numbering.

- You can add your own classes to cells, for example to highlight solution letters or to blacken only internal empty squares.

- If your grid is barred and you use CSS border collapse: If two neighboring cells have different borders, the thicker border wins, in case of a tie, the one from the top or left cell.

- Unfortunately, browsers do not allow using local storage for local files (i.e. files opened via `file:///`). The other parts of the script still work, but progress is lost on page reloads.

## Contribution

Please leave an issue if you run into any bugs. I would also be interested to hear from you if you use a screenreader and have ideas on how to create a usable interface. Lastly, you can contribute translations.
