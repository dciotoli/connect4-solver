from libc.stdint cimport uint64_t
from libc.stdio cimport printf, FILE, fopen, fwrite, fclose, fread, feof

cimport board
from minimax cimport alpha_beta_negamax_search


cdef int possible_count = 0
cdef int num_visited = 0


cdef void explore(uint64_t position, uint64_t mask, int depth, set visited, set final_set):
    cdef int i
    cdef uint64_t new_pos, new_mask, key
    global num_visited

    key = board.key3(position, mask)

    if key in visited:
        return

    if depth >= 0:
        # Store result
        visited.add(key)
        num_visited += 1
        if num_visited % 100000 == 0:
            printf(b'Visited %d nodes...\n', num_visited)

    if depth == 0:
        if not board.can_win_next(position, mask):
            final_set.add(key)
        return

    for i in range(board.NUM_COLS):
        # Check if it can be played and is not a winning move
        if (board.possible_moves(mask) & board.column_mask(i)):
            new_pos, new_mask = board.take_turn(position, mask, i)
            if not board.check_winning_position(new_pos ^ new_mask):
                explore(new_pos, new_mask, depth - 1, visited, final_set)


cdef void create_position_file(int depth, set book_set, bytes book_file_name, uint64_t min_key, bint append) except *:
    cdef uint64_t key, pos, mask
    cdef int score, max_score, min_score, total_complete, num_to_do
    cdef FILE * f

    total_complete = 0
    num_to_do = len(book_set)
    min_score = -(board.NUM_COLS * board.NUM_ROWS - (depth + 1)) // 2
    max_score = (board.NUM_COLS * board.NUM_ROWS - depth) // 2
    if not append:
        f = fopen(book_file_name, b'wb')
    else:
        f = fopen(book_file_name, b'ab')

    if not f:
        raise FileNotFoundError('Cannot find file!')

    # ToDo: parallelize me, add null window search, design for stop and resume
    for key in sorted(book_set):
        if key > min_key:
            pos, mask = board.key3_to_pos_and_mask(key)
            score = alpha_beta_negamax_search(pos, mask, min_score, max_score)
            fwrite(&key, sizeof(key), 1, f)
            fwrite(&score, sizeof(score), 1, f)
            total_complete += 1
            if not total_complete % (1 + (num_to_do // 1000)):
                printf(b'%.2f%% complete (#%d)...\n',
                       (100 * <float> total_complete / <float> num_to_do), total_complete)

    fclose(f)


cdef void load_book_file(dict book_dict, bytes book_file_name) except *:
    cdef FILE * f
    cdef int score
    cdef uint64_t key

    f = fopen(book_file_name, b'rb')

    if not f:
        raise FileNotFoundError('Cannot find file!')

    # read key / score
    while True:
        # read key
        fread(&key, sizeof(key), 1, f)
        if feof(f):
            break

        # read score
        fread(&score, sizeof(score), 1, f)
        if feof(f):
            break

        # store in dict
        book_dict[key] = score

    fclose(f)


cpdef test_load_book_file():
    cdef dict book_dict
    cdef bytes book_file_name
    cdef uint64_t pos, mask, key3
    cdef int min_score, max_score, bmin, bmax, score = 0

    min_score = -(board.NUM_COLS * board.NUM_ROWS - (10 + 1)) // 2
    max_score = (board.NUM_COLS * board.NUM_ROWS - 10) // 2

    book_dict = {}
    book_file_name = b'board.all_positions.6x7.10ply.dat'
    game_str = '4444442333'

    pos, mask = board.from_game_string(game_str)
    key3 = board.key3(pos, mask)
    score = alpha_beta_negamax_search(pos, mask, min_score, max_score)
    printf(b'score was: %d\n', score)

    load_book_file(book_dict, book_file_name)
    printf(b'length of book: %d\n', len(book_dict))
    printf(b'book dict was: %d\n', <int> book_dict.get(key3, -999))

    assert score == book_dict.get(key3, -999)
    printf(b'Scores were equal: %d, test passed!\n', score)

    bmin = min(book_dict.values())
    bmax = max(book_dict.values())

    printf(b'Book min: %d\nBook max: %d\n', bmin, bmax)



cpdef test_explore(int depth):
    cdef set final_set = set({})

    explore(<uint64_t> 0, <uint64_t> 0, depth, set({}), final_set)
    printf(b'Final set length: %d\n', len(final_set))


cpdef generate_positions(int book_ply):
    cdef dict book_dict = {}
    cdef set book_set = set({})
    cdef set final_set = set({})
    cdef bytes book_file_name
    global num_visited

    book_file_name = bytes(
        f'board.all_positions.{board.NUM_ROWS}x{board.NUM_COLS}.{book_ply}ply.dat', encoding='utf-8')
    num_visited = 0

    printf(b'Exploring all moves up to depth %d...\n', book_ply)
    explore(<uint64_t> 0, <uint64_t> 0, book_ply, book_set, final_set)

    printf(b'Full set length: %d\n', len(book_set))
    printf(b'Final set length: %d\n', len(final_set))

    create_position_file(book_ply, final_set, book_file_name, 0, 0)


cpdef generate_single_position(str game_string):
    cdef dict book_dict = {}
    cdef set final_set = set({})
    cdef bytes book_file_name
    global num_visited

    book_file_name = bytes(
        f'board.position.{board.NUM_ROWS}x{board.NUM_COLS}.{game_string}.dat', encoding='utf-8')
    num_visited = 1

    position, mask = board.from_game_string(game_string)
    final_set.add(board.key3(position, mask))

    printf(b'Final set length: %d\n', len(final_set))

    create_position_file(len(game_string), final_set, book_file_name, 0, 0)


cpdef test_key3(uint64_t position, uint64_t mask):
    cdef uint64_t mirror_pos, mirror_mask
    cdef int i

    mirror_pos = 0
    mirror_mask = 0

    board.print_board(position, mask, 0, 1)

    for i in range(board.NUM_COLS):
        printf(b'Can make move for column %d? %llu.\n', i + 1, board.possible_moves(mask) & board.column_mask(i))
        mirror_pos += ((position & board.column_mask(i)) >> (i * (board.NUM_ROWS + 1)))\
                      << ((board.NUM_ROWS + 1) * (board.NUM_COLS - i - 1))
        mirror_mask += ((mask & board.column_mask(i)) >> (i * (board.NUM_ROWS + 1)))\
                       << ((board.NUM_ROWS + 1) * (board.NUM_COLS - i - 1))

    # generate mirror image position
    board.print_board(mirror_pos, mirror_mask, 0, 1)

    printf(b'KEY1: %llu\n', board.key3(position, mask))
    printf(b'KEY2: %llu\n', board.key3(mirror_pos, mirror_mask))
    assert board.key3(position, mask) == board.key3(mirror_pos, mirror_mask)
    printf(b'Success! Key3 of mirror images are equal...\n\n')

    printf(b'Base 3 Key: \n')
    mirror_pos, mirror_mask = board.key3_to_pos_and_mask(board.key3(position, mask))
    board.print_board(mirror_pos, mirror_mask, 0, 1)

    assert board.key3(mirror_pos, mirror_mask) == board.key3(position, mask)
    printf(b'Success! Was able to translate key3 to pos/mask...\n')


cpdef test_opening_book_single_position(str game_string):
    cdef dict book_dict
    cdef bytes book_file_name
    cdef uint64_t pos, mask, key3
    cdef int min_score, max_score, score = 0

    book_dict = {}
    min_score = -(board.NUM_COLS * board.NUM_ROWS - (len(game_string) + 1)) // 2
    max_score = (board.NUM_COLS * board.NUM_ROWS - len(game_string)) // 2

    generate_single_position(game_string)
    book_file_name = bytes(
        f'board.position.{board.NUM_ROWS}x{board.NUM_COLS}.{game_string}.dat', encoding='utf-8')

    pos, mask = board.from_game_string(game_string)
    key3 = board.key3(pos, mask)
    score = alpha_beta_negamax_search(pos, mask, min_score, max_score)
    printf(b'score was: %d\n', score)

    load_book_file(book_dict, book_file_name)
    printf(b'length of book: %d\n', len(book_dict))
    printf(b'book dict was: %d\n', <int> book_dict.get(key3, -999))

    assert score == book_dict.get(key3, -999)
    printf(b'Scores were equal: %d, test passed!\n', score)

