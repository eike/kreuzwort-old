# kreuzwort.coffee

kreuzwort.coffee is a Coffeescript for displaying beautiful and interactive crosswords on webpages. See it in action here: [kifu.eu](http://kifu.eu) (Crosswords in German)

## Features

* Easy-to-use cursor-based crossword navigation
* Pure coffeescript or javascript, no libraries or frameworks required
* Arbitrary crossword shapes (no non-square cells, though)
* Support for barred and boxed grids
* Saves solving progress in local storage
* Light-weight markup

## User controls

* Clicking on a cell sets the cursor in front of that cell and changes direction if sensible
* Typing places or replaces text, use Space for deleting forwards, Backspace for deleting backwards
* Tab or clicking the cell behind the cursor changes writing direction
* Enter a number to jump to the corresponding starting cell
* Click on a hint to select the corresponding cells in the grid

## Using the script

1. Embed the script in your page, e.g.

       <script type="javascript" src="kreuzwort.js"></script>

2. Prepare your grid: kreuzwort.coffee expects some kind of container (say `article` or `div`) that contains a `table` representing the grid. In this table:
   - Non-empty cells represent input cells, completely empty cells are blocks.
   - Hints can be placed by setting the `data-hint-vertical` and/or `data-hint-horizontal` attributes of the starting cell. To create a bar without a hint leave the value of the attribute blank. These empty hints will not show up in the hint listing. The values of the hint attributes are used as innerHTML, so you can add HTML tags for special styling, but you also need to be careful with user-generated content.

3. Create an instance of the Kreuzwort class:

       kreuzwort = new Kreuzwort(container, features, strings)
    
   `features` is an object that allows you turn certain features on and off by setting the following to `true` or `false`:
   
   Property | Description
   ---------|------------
   `check` | Whether it should be possible to check the solution. So far, it is only possible by checking the complete puzzle. Add the value return value of the `currentHash` method on a completed crossword as the attribute `data-solution-hash` to the table when using this feature.
   `clear` | Whether to show a link to completely reset the puzzle.
   `print` | Whether to show ‘Print’ and ‘Print empty’ links
   `hintListing` | Whether to create the listing of all hints. Setting this to false gives a more compact view of the crossword; the hints are still accessible by selecting cells in the grid.
   `writeNewCells` | Whether cells that are not marked as entry cells (by filling them with a space) can be written to. This is intended to be used when creating a crossword grid.
   `setBars` | Whether bars can be set by pressing Enter. Intended for creation of crosswords.
   `createGrid` | Whether a link to output the HTML of the (empty) grid should be displayed. Intended for creation.
   
   The crossword object has the presets `Kreuzwort.featuresFull`, `Kreuzwort.featuresCompact` and `Kreuzwort.featuresConstruction` as features objects.
   
   `strings` is an object with translation strings. Look at the `Kreuzwort.languages` object to see all the strings.
   
   You can have multiple instances of Kreuzwort on one page.

4. Add a stylesheet. The script will add the class `current-word` to all cells of the currently selected words and the classes `cursor-top`, `cursor-bottom`, `cursor-left` or `cursor-right` to the cells below, above, right of and left of the cursor. It will also add the following things after the grid:
   - a div `current-hint` containing a span with class `current-hint-position` for the position of the word (i.e. 'Down, 7') and the hint
   - a div `controls` containing the buttons for checking, clearing, printing etc.
   - headings h2 and ordered lists of hints for Across and Down

### Tips

- Kreuzwort.coffee does not add numbers to the cells, but you can do that with CSS. Kreuzwort.coffee considers a cell to be numbered when it has a non-empty data-hint-vertical or data-hint-horizontal attribute. The following CSS selector selects these cells:

      td[data-hint-vertical]:not([data-hint-vertical='']), td[data-hint-horizontal]:not([data-hint-horizontal=''])

  You can add numbers to these cells with CSS counters.

- You can add your own classes to cells, for example to highlight solution letters or to blacken only internal empty squares.

- If your grid is barred and you use CSS border collapse: If two neighboring cells have different borders, the thicker border wins, in case of a tie, the one from the top or left cell.

## Contribution

Please leave an issue if you run into any bugs. I would also be interested to hear from you if you use a screenreader and have ideas on how to create a usable interface. Lastly, you can contribute translations.
