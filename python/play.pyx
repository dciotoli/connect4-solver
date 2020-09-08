from libc.stdio cimport printf
from libc.stdint cimport uint64_t
from minimax import score_move, init_opening_book
cimport board
import time


NUM_COLS = board.NUM_COLS
POSSIBLE_MOVES = [i for i in range(NUM_COLS)]


cpdef play_connect4(go_first=True, show_scores=True, config=None):
    # Initialize board position
    cdef bint game_over = False
    cdef bint current_player = go_first
    cdef uint64_t pos, mask
    cdef int col, turn_count
    cdef list scores
    cdef bytes opening_book

    if config is None:
        config = {}

    turn_count = 0
    aspirational_search = config.get('aspirational_search', 1)
    board_str = config.get('board_string', '4444413555533')
    opening_book = config.get('opening_book')

    if opening_book:
        printf(b'Loading opening book file...\n')
        init_opening_book(opening_book)

    if go_first:
        turn_count, pos, mask = 0, 0, 0
        for x_col in board_str:
            pos, mask = board.take_turn(pos, mask, int(x_col) - 1)
            turn_count += 1
    else:
        raise NotImplemented('Going second not yet implemented')

    while not game_over:
        board.print_board(pos, mask, show_scores=show_scores, cur_player=current_player)

        if current_player:
            try:
                col = int(input('Select a column: '))
                if col < 0 or col >= NUM_COLS:
                    raise ValueError('Invalid column value')
                if not (board.possible_moves(mask) & board.column_mask(col)):
                    raise ValueError('Invalid column value')
            except ValueError:
                printf(b'Invalid input, try again...\n')
                continue
        else:
            # Evaluate possible moves and select
            t1 = time.time()
            scores = [score_move(pos, mask, i, aspirational_search) for i in POSSIBLE_MOVES]
            t2 = time.time()

            # ToDo: Make printing of scores and time taken dynamic
            printf(b'%s', bytes(','.join([f'{x}' for x in scores]) + '\n', encoding='utf-8'))
            col = POSSIBLE_MOVES[scores.index(max(scores))]
            printf(b'%s', bytes('Col: {}, {:.4f} seconds elapsed.\n'.format(str(col), t2 - t1), encoding='utf-8'))

        # make the move
        pos, mask = board.take_turn(pos, mask, col)
        turn_count += 1

        if board.check_winning_position(mask ^ pos):
            game_over = True
        current_player = not current_player

    board.print_board(pos, mask, show_scores=show_scores, cur_player=current_player)
    printf(b'############################\n')
    printf(b'##                        ##\n')
    printf(b'##   G A M E    O V E R   ##\n')
    printf(b'##                        ##\n')
    if not current_player:
        printf(b'##    Y O U     W I N !   ##\n')
    else:
        printf(b'##    Y O U     L O S E   ##\n')
    printf(b'##                        ##\n')
    printf(b'############################\n')

    return