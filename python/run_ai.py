from play import play_connect4
from move_sorter import test_move_sorter
from transposition_table import test_transposition_table
from opening_book import generate_positions, test_key3
from board import from_game_string

# ToDo: Create opening book of all 8 ply moves with their evaluations

if __name__ == '__main__':
    go_first = True
    show_scores = True
    run_tests = False
    play_game = False
    board_string = '12345671'
    config = {
        'board_string': board_string,
        'aspirational_search': 1
    }

    generate_positions(12)

    if run_tests:
        test_transposition_table()
        test_move_sorter()
        pos, mask = from_game_string(board_string)

        test_key3(pos, mask)

    if play_game:
        play_connect4(go_first=go_first, show_scores=show_scores, config=config)