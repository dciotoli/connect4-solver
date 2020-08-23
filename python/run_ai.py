from play import play_connect4
from move_sorter import test_move_sorter
from transposition_table import test_transposition_table
from opening_book import generate_positions, test_key3
from board import from_game_string
import argparse


def play(args):
    go_first = True  # ToDo: Add option to go second
    show_scores = True  # ToDo: add option to show/hide scores for player
    board_string = args.board_string
    config = {
        'board_string': board_string,
        'aspirational_search': 1 if not args.disable_aspirational_search else 0
    }
    play_connect4(go_first=go_first, show_scores=show_scores, config=config)


def run_test(args):
    print('Made it!')
    test_transposition_table()
    test_move_sorter()
    pos, mask = from_game_string(args.board_string)

    test_key3(pos, mask)


def create_opening_book(args):
    generate_positions(args.ply)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(title='subcommands', description='valid subcommands', help='subcommand help')

    play_parser = subparsers.add_parser('play', help='play help')
    test_parser = subparsers.add_parser('test', help='test help')
    book_parser = subparsers.add_parser('create-opening-book', help='create-opening-book help')

    play_parser.add_argument('--board_string', default='12345671',
                             help='Enter a board string to play the game with a custom configuration')
    play_parser.add_argument('--disable_aspirational_search', help='Disable aspirational search', action='store_true',
                             default=False)
    play_parser.set_defaults(func=play)

    book_parser.add_argument('--ply', type=int, help='Enter a number between 8 and 12.', required=True)
    book_parser.set_defaults(func=create_opening_book)

    test_parser.add_argument('--board_string', default='12345671',
                             help='Enter a board string to play the game with a custom configuration')
    test_parser.set_defaults(func=run_test)

    args = parser.parse_args()
    args.func(args)
