# frozen_string_literal: true

# rbs_inline: enabled

# Sqids (pronounced "squids") is a library that generates short, unique, non-sequential IDs
# from numbers. It's useful for obfuscating database IDs, creating URL-friendly identifiers,
# and generating human-readable codes.
#
# Key features:
# - Reversible: encoded IDs can be decoded back to the original numbers
# - Customizable: supports custom alphabets, minimum lengths, and blocklists
# - Collision-free: same input always produces the same output
# - Blocklist filtering: automatically regenerates IDs that contain blocked words
#
# The algorithm uses a shuffling mechanism based on the input numbers to select characters
# from a customized alphabet, ensuring that sequential numbers produce non-sequential IDs.
#
class MySqids
  # @rbs @alphabet: Array[Integer]
  # @rbs @min_length: Integer
  # @rbs @blocklist: (Array[String] | Set[String])

  # @rbs self.@DEFAULT_ALPHABET: String
  DEFAULT_ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

  # Default minimum length of 0 means no padding is applied to generated IDs
  # @rbs self.@DEFAULT_MIN_LENGTH: Integer
  DEFAULT_MIN_LENGTH = 0
  # rubocop:disable Metrics/CollectionLiteralLength, Layout/LineLength
  # Default blocklist containing words that should not appear in generated IDs
  # The blocklist prevents offensive or inappropriate words from appearing in IDs by
  # regenerating IDs that contain these patterns.
  # @rbs self.@DEFAULT_BLOCKLIST: Array[String]
  DEFAULT_BLOCKLIST = %w[0rgasm 1d10t 1d1ot 1di0t 1diot 1eccacu10 1eccacu1o 1eccacul0
    1eccaculo 1mbec11e 1mbec1le 1mbeci1e 1mbecile a11upat0 a11upato a1lupat0 a1lupato aand ah01e ah0le aho1e ahole al1upat0 al1upato allupat0 allupato ana1 ana1e anal anale anus arrapat0 arrapato arsch arse ass b00b b00be b01ata b0ceta b0iata b0ob b0obe b0sta b1tch b1te b1tte ba1atkar balatkar bastard0 bastardo batt0na battona bitch bite bitte bo0b bo0be bo1ata boceta boiata boob boobe bosta bran1age bran1er bran1ette bran1eur bran1euse branlage branler branlette branleur branleuse c0ck c0g110ne c0g11one c0g1i0ne c0g1ione c0gl10ne c0gl1one c0gli0ne c0glione c0na c0nnard c0nnasse c0nne c0u111es c0u11les c0u1l1es c0u1lles c0ui11es c0ui1les c0uil1es c0uilles c11t c11t0 c11to c1it c1it0 c1ito cabr0n cabra0 cabrao cabron caca cacca cacete cagante cagar cagare cagna cara1h0 cara1ho caracu10 caracu1o caracul0 caraculo caralh0 caralho cazz0 cazz1mma cazzata cazzimma cazzo ch00t1a ch00t1ya ch00tia ch00tiya ch0d ch0ot1a ch0ot1ya ch0otia ch0otiya ch1asse ch1avata ch1er ch1ng0 ch1ngadaz0s ch1ngadazos ch1ngader1ta ch1ngaderita ch1ngar ch1ngo ch1ngues ch1nk chatte chiasse chiavata chier ching0 chingadaz0s chingadazos chingader1ta chingaderita chingar chingo chingues chink cho0t1a cho0t1ya cho0tia cho0tiya chod choot1a choot1ya chootia chootiya cl1t cl1t0 cl1to clit clit0 clito cock cog110ne cog11one cog1i0ne cog1ione cogl10ne cogl1one cogli0ne coglione cona connard connasse conne cou111es cou11les cou1l1es cou1lles coui11es coui1les couil1es couilles cracker crap cu10 cu1att0ne cu1attone cu1er0 cu1ero cu1o cul0 culatt0ne culattone culer0 culero culo cum cunt d11d0 d11do d1ck d1ld0 d1ldo damn de1ch deich depp di1d0 di1do dick dild0 dildo dyke encu1e encule enema enf01re enf0ire enfo1re enfoire estup1d0 estup1do estupid0 estupido etr0n etron f0da f0der f0ttere f0tters1 f0ttersi f0tze f0utre f1ca f1cker f1ga fag fica ficker figa foda foder fottere fotters1 fottersi fotze foutre fr0c10 fr0c1o fr0ci0 fr0cio fr0sc10 fr0sc1o fr0sci0 fr0scio froc10 froc1o froci0 frocio frosc10 frosc1o frosci0 froscio fuck g00 g0o g0u1ne g0uine gandu go0 goo gou1ne gouine gr0gnasse grognasse haram1 harami haramzade hund1n hundin id10t id1ot idi0t idiot imbec11e imbec1le imbeci1e imbecile j1zz jerk jizz k1ke kam1ne kamine kike leccacu10 leccacu1o leccacul0 leccaculo m1erda m1gn0tta m1gnotta m1nch1a m1nchia m1st mam0n mamahuev0 mamahuevo mamon masturbat10n masturbat1on masturbate masturbati0n masturbation merd0s0 merd0so merda merde merdos0 merdoso mierda mign0tta mignotta minch1a minchia mist musch1 muschi n1gger neger negr0 negre negro nerch1a nerchia nigger orgasm p00p p011a p01la p0l1a p0lla p0mp1n0 p0mp1no p0mpin0 p0mpino p0op p0rca p0rn p0rra p0uff1asse p0uffiasse p1p1 p1pi p1r1a p1rla p1sc10 p1sc1o p1sci0 p1scio p1sser pa11e pa1le pal1e palle pane1e1r0 pane1e1ro pane1eir0 pane1eiro panele1r0 panele1ro paneleir0 paneleiro patakha pec0r1na pec0rina pecor1na pecorina pen1s pendej0 pendejo penis pip1 pipi pir1a pirla pisc10 pisc1o pisci0 piscio pisser po0p po11a po1la pol1a polla pomp1n0 pomp1no pompin0 pompino poop porca porn porra pouff1asse pouffiasse pr1ck prick pussy put1za puta puta1n putain pute putiza puttana queca r0mp1ba11e r0mp1ba1le r0mp1bal1e r0mp1balle r0mpiba11e r0mpiba1le r0mpibal1e r0mpiballe rand1 randi rape recch10ne recch1one recchi0ne recchione retard romp1ba11e romp1ba1le romp1bal1e romp1balle rompiba11e rompiba1le rompibal1e rompiballe ruff1an0 ruff1ano ruffian0 ruffiano s1ut sa10pe sa1aud sa1ope sacanagem sal0pe salaud salope saugnapf sb0rr0ne sb0rra sb0rrone sbattere sbatters1 sbattersi sborr0ne sborra sborrone sc0pare sc0pata sch1ampe sche1se sche1sse scheise scheisse schlampe schwachs1nn1g schwachs1nnig schwachsinn1g schwachsinnig schwanz scopare scopata sexy sh1t shit slut sp0mp1nare sp0mpinare spomp1nare spompinare str0nz0 str0nza str0nzo stronz0 stronza stronzo stup1d stupid succh1am1 succh1ami succhiam1 succhiami sucker t0pa tapette test1c1e test1cle testic1e testicle tette topa tr01a tr0ia tr0mbare tr1ng1er tr1ngler tring1er tringler tro1a troia trombare turd twat vaffancu10 vaffancu1o vaffancul0 vaffanculo vag1na vagina verdammt verga w1chsen wank wichsen x0ch0ta x0chota xana xoch0ta xochota z0cc01a z0cc0la z0cco1a z0ccola z1z1 z1zi ziz1 zizi zocc01a zocc0la zocco1a zoccola].freeze
  # rubocop:enable Metrics/CollectionLiteralLength, Layout/LineLength

  # Maximum integer value that can be encoded
  # Uses Integer::MAX if available (Ruby 2.4+), otherwise calculates the max fixnum value
  # based on the platform's word size
  MAX_INT = defined?(Integer::MAX) ? Integer::MAX : ((2**((0.size * 8) - 2)) - 1)

  # Returns the maximum integer value that can be safely encoded
  # @rbs () -> Integer
  def self.max_value
    MAX_INT
  end

  # Initializes a new MySqids encoder with custom options
  #
  # @param options [Hash] Configuration options
  # @option options [String, Array<String>] :alphabet Custom alphabet to use for encoding
  #   (default: DEFAULT_ALPHABET). Must be at least 3 characters and contain only single-byte chars.
  # @option options [Integer] :min_length Minimum length for generated IDs (default: 0).
  #   IDs shorter than this will be padded. Must be between 0 and 255.
  # @option options [Array<String>, Set<String>] :blocklist Words to exclude from generated IDs
  #   (default: DEFAULT_BLOCKLIST). Words must be at least 3 characters long.
  #
  # @raise [ArgumentError] If alphabet contains multibyte characters
  # @raise [ArgumentError] If alphabet is shorter than 3 characters
  # @raise [ArgumentError] If alphabet contains duplicate characters
  # @raise [TypeError] If min_length is not between 0 and 255
  #
  # @rbs (?Hash[Symbol, untyped] options) -> void
  def initialize(options = {})
    alphabet = options[:alphabet] || DEFAULT_ALPHABET
    min_length = options[:min_length] || DEFAULT_MIN_LENGTH
    blocklist = options[:blocklist] || DEFAULT_BLOCKLIST

    raise ArgumentError, "Alphabet cannot contain multibyte characters" if contains_multibyte_chars?(alphabet)
    raise ArgumentError, "Alphabet length must be at least 3" if alphabet.length < 3

    alphabet = alphabet.chars unless alphabet.is_a?(Array)

    if alphabet.uniq.size != alphabet.length
      raise ArgumentError,
        "Alphabet must contain unique characters"
    end

    min_length_limit = 255
    unless min_length.is_a?(Integer) && min_length >= 0 && min_length <= min_length_limit
      raise TypeError,
        "Minimum length has to be between 0 and #{min_length_limit}"
    end

    # Filter the blocklist to only include words that:
    # 1. Are at least 3 characters long
    # 2. Only contain characters that exist in the alphabet (case-insensitive)
    # This ensures we don't try to block words that could never appear in generated IDs
    filtered_blocklist = if options[:blocklist].nil? && options[:alphabet].nil?
      # If using default blocklist and alphabet, skip filtering since we know it's valid
      blocklist
    else
      downcased_alphabet = alphabet.map(&:downcase)
      # Only keep words that can be formed from the alphabet
      blocklist.select do |word|
        word.length >= 3 && (word.downcase.chars - downcased_alphabet).empty?
      end.to_set(&:downcase)
    end

    # Store the alphabet as an array of integer codepoints after shuffling
    # Shuffling ensures the alphabet order is unique to this instance
    @alphabet = shuffle(alphabet.map(&:ord))
    @min_length = min_length
    @blocklist = filtered_blocklist
  end

  # Encodes an array of integers into a single Sqids string
  #
  # The encoding process:
  # 1. Validates all numbers are in valid range (0 to MAX_INT)
  # 2. Generates a prefix character based on the numbers and alphabet
  # 3. Encodes each number using a shuffled alphabet
  # 4. Separates encoded numbers with the first character of the shuffled alphabet
  # 5. Pads the result if it's shorter than min_length
  # 6. Regenerates if the result contains blocklisted words
  #
  # @param numbers [Array<Integer>] Array of non-negative integers to encode
  # @return [String] The encoded Sqids string
  # @raise [ArgumentError] If any number is outside the valid range (0 to MAX_INT)
  #
  # @example
  #   sqids.encode([1, 2, 3])  # => "86Rf07"
  #   sqids.encode([])         # => ""
  #
  # @rbs (Array[Integer] numbers) -> String
  def encode(numbers)
    return "" if numbers.empty?

    # Validate that all numbers are within the acceptable range
    in_range_numbers = numbers.filter_map { |n|
      i = n.to_i
      i if i.between?(0, MAX_INT)
    }
    unless in_range_numbers.length == numbers.length
      raise ArgumentError,
        "Encoding supports numbers between 0 and #{MAX_INT}"
    end

    encode_numbers(in_range_numbers)
  end

  # Decodes a Sqids string back into the original array of integers
  #
  # The decoding process mirrors the encoding:
  # 1. Validates all characters exist in the alphabet
  # 2. Extracts the prefix to determine the alphabet offset
  # 3. Rotates and reverses the alphabet based on the offset
  # 4. Splits the ID by separator characters (first char of shuffled alphabet)
  # 5. Converts each chunk back to its original number
  # 6. Re-shuffles the alphabet between chunks
  #
  # @param id [String] The Sqids string to decode
  # @return [Array<Integer>] Array of integers that were encoded, or empty array if invalid
  #
  # @example
  #   sqids.decode("86Rf07")  # => [1, 2, 3]
  #   sqids.decode("")        # => []
  #   sqids.decode("xyz")     # => [] (if 'xyz' contains invalid chars)
  #
  # @rbs (String id) -> Array[Integer]
  def decode(id)
    ret = [] #: Array[Integer]

    return ret if id.empty?

    # Convert string to array of character codepoints for processing
    id = id.chars.map(&:ord)

    # Validate that all characters in the ID exist in our alphabet
    # If any character is invalid, return empty array
    id.each do |c|
      return ret unless @alphabet.include?(c)
    end

    # Extract the prefix (first character) which determines the alphabet transformation
    prefix = id[0]
    offset = @alphabet.index(prefix)
    # If prefix not found in alphabet, return empty (should never happen after validation)
    return [] if offset.nil?

    # Reconstruct the alphabet used during encoding
    alphabet = rotate_and_reverse_alphabet(@alphabet, offset)

    # Remove the prefix, leaving only the encoded number segments
    id = id[1, id.length] || [] #: Array[Integer]

    # Decode each segment separated by the separator character
    while id.length.positive?
      separator = alphabet[0]
      chunks = split_array(id, separator)
      if chunks.any?
        # Empty chunk indicates invalid ID structure
        return ret if chunks[0] == []

        # Convert the chunk back to its original number
        ret.push(to_number(chunks[0], alphabet))
        # Re-shuffle alphabet before processing next segment (matches encoding)
        alphabet = shuffle(alphabet) if chunks.length > 1
      end

      # Continue with the next segment, or empty array if no more segments
      id = (chunks.length > 1) ? chunks[1] : []
    end

    ret
  end

  private

  # Splits an array into two parts at the first occurrence of a separator
  #
  # This is used during decoding to split the encoded ID at separator characters,
  # which mark the boundaries between encoded numbers.
  #
  # @param arr [Array<Integer>] The array to split (character codepoints)
  # @param separator [Integer] The separator character codepoint to split on
  # @return [Array<Array<Integer>>] An array containing the left part (before separator)
  #   and right part (after separator). If separator not found, returns [arr].
  #
  # @example
  #   split_array([1, 2, 3, 4, 5], 3)  # => [[1, 2], [4, 5]]
  #   split_array([1, 2, 3], 9)        # => [[1, 2, 3]]
  #
  # @rbs (Array[Integer] arr, Integer separator) -> Array[Array[Integer]]
  def split_array(arr, separator)
    index = arr.index(separator)
    return [arr] if index.nil?

    left = arr[0...index] #: Array[Integer]
    right = arr[index + 1..] #: Array[Integer]

    [left, right]
  end

  # Shuffles an array of character codepoints using a consistent, deterministic algorithm
  #
  # This is a key part of the Sqids algorithm. The shuffle is deterministic and reversible,
  # meaning the same input always produces the same output. The algorithm performs a series
  # of swaps based on the current index and character values.
  #
  # The shuffle ensures that:
  # - Sequential numbers don't produce sequential IDs
  # - The same alphabet configuration always produces the same shuffle
  # - The transformation is reversible
  #
  # @param chars [Array<Integer>] Array of character codepoints to shuffle
  # @return [Array<Integer>] The shuffled array (modifies in place and returns)
  #
  # @rbs (Array[Integer] chars) -> Array[Integer]
  def shuffle(chars)
    i = 0
    length = chars.length
    j = length - 1
    while j > 0
      r = ((i * j) + chars[i] + chars[j]) % length
      chars[i], chars[r] = chars[r], chars[i]
      i += 1
      j -= 1
    end

    chars
  end

  # Internal method to encode an array of numbers into a Sqids string
  #
  # This is the core encoding logic. The process:
  # 1. Calculates an offset based on the numbers and alphabet (ensures uniqueness)
  # 2. Applies an increment if this is a retry (for blocklist filtering)
  # 3. Selects a prefix character from the alphabet at the offset position
  # 4. Rotates and reverses the alphabet based on the offset
  # 5. Encodes each number and separates them with the first shuffled alphabet character
  # 6. Pads to minimum length if needed
  # 7. Checks against blocklist and retries with incremented offset if needed
  #
  # @param numbers [Array<Integer>] Array of integers to encode
  # @param increment [Integer] Retry counter for blocklist collision avoidance (default: 0)
  # @return [String] The encoded Sqids string
  # @raise [ArgumentError] If max retry attempts (alphabet length) is exceeded
  #
  # @rbs (Array[Integer] numbers, ?increment: Integer) -> String
  def encode_numbers(numbers, increment: 0)
    alphabet_length = @alphabet.length
    raise ArgumentError, "Reached max attempts to re-generate the ID" if increment > alphabet_length

    numbers_length = numbers.length
    offset = numbers_length
    i = 0
    while i < numbers_length
      offset += @alphabet[numbers[i] % alphabet_length] + i
      i += 1
    end
    offset %= alphabet_length
    offset = (offset + increment) % alphabet_length

    prefix = @alphabet[offset]
    # Now working with modified alphabet
    alphabet = rotate_and_reverse_alphabet(@alphabet, offset)
    id = [prefix]

    i = 0
    while i < numbers_length
      to_id(id, numbers[i], alphabet)

      if i < numbers_length - 1
        id.push(alphabet[0])
        alphabet = shuffle(alphabet)
      end

      i += 1
    end

    if @min_length > id.length
      id << alphabet[0]

      while (@min_length - id.length) > 0
        alphabet = shuffle(alphabet)
        slice_length = [@min_length - id.length, alphabet.length].min
        alphabet_slice = alphabet.slice(0, slice_length) #: Array[Integer]
        id.concat alphabet_slice
      end
    end

    id = id.pack("U*")

    id = encode_numbers(numbers, increment: increment + 1) if blocked_id?(id)

    id
  end

  # Converts a single number into its encoded representation and appends to the ID
  #
  # This implements a base conversion algorithm where:
  # - The base is (alphabet_length - 1) because the first character is reserved as separator
  # - Characters are added at the start_index position (building the number representation)
  # - The process continues until the number is fully converted
  #
  # The algorithm repeatedly:
  # 1. Takes the remainder (mod alphabet_length - 1) to get the next character index
  # 2. Adds 1 to skip the first character (reserved as separator)
  # 3. Inserts the character into the ID
  # 4. Divides the number by the base to continue with the quotient
  #
  # @param id [Array<Integer>] The ID array being built (modified in place)
  # @param num [Integer] The number to encode
  # @param alphabet [Array<Integer>] The alphabet to use for encoding
  # @return [void] Modifies id in place
  #
  # @rbs (Array[Integer] id, Integer num, Array[Integer] alphabet) -> void
  def to_id(id, num, alphabet)
    result = num
    start_index = id.length
    # We are effectively removing the first character of the alphabet, hence the -1 on length and the +1 on the index
    alphabet_length = alphabet.length - 1
    while true # rubocop:disable Style/InfiniteLoop
      new_char_index = (result % alphabet_length) + 1
      new_char = alphabet[new_char_index]
      # id is an array, we want to insert the new char at the start_index position.
      id.insert(start_index, new_char)
      result /= alphabet_length
      break if result <= 0
    end
  end

  # Converts an encoded ID chunk back into its original number
  #
  # This is the inverse of to_id, implementing base conversion from the custom alphabet
  # back to a decimal integer. It processes each character in the ID chunk, treating it
  # as a digit in a positional number system with base (alphabet_length - 1).
  #
  # The algorithm:
  # 1. Finds each character's index in the alphabet
  # 2. Subtracts 1 (because we added 1 during encoding to skip separator)
  # 3. Multiplies accumulator by base and adds the digit value
  #
  # @param id [Array<Integer>] The encoded ID chunk (character codepoints)
  # @param alphabet [Array<Integer>] The alphabet used during encoding
  # @return [Integer] The decoded number
  # @raise [RuntimeError] If a character is not found in the alphabet
  #
  # @rbs (Array[Integer] id, Array[Integer] alphabet) -> Integer
  def to_number(id, alphabet)
    # We are effectively removing the first character of the alphabet, hence the -1 on length and the -1 on the index
    alphabet_length = alphabet.length - 1
    id.reduce(0) do |a, v|
      v_index = alphabet.index(v)
      raise "Character #{v} not found in alphabet" if v_index.nil?
      (a * alphabet_length) + v_index - 1
    end
  end

  # Checks if a generated ID contains any blocklisted words
  #
  # The filtering rules vary by word and ID length:
  # - For very short IDs/words (≤3 chars): requires exact match
  # - For words containing digits: checks if ID starts or ends with the word
  # - For other words: checks if word appears anywhere in the ID
  #
  # This helps prevent offensive or inappropriate words from appearing in generated IDs
  # while minimizing false positives.
  #
  # @param id [String] The generated ID to check
  # @return [Boolean] true if the ID contains a blocklisted word, false otherwise
  #
  # @rbs (String id) -> bool
  def blocked_id?(id)
    id = id.downcase

    @blocklist.any? do |word|
      if word.length <= id.length
        if id.length <= 3 || word.length <= 3
          id == word
        elsif word.match?(/\d/)
          id.start_with?(word) || id.end_with?(word)
        else
          id.include?(word)
        end
      end
    end
  end

  # Checks if a string contains any multibyte (non-ASCII) characters
  #
  # Sqids requires single-byte characters only because:
  # - The algorithm uses character codepoints (ord) for shuffling and encoding
  # - Multibyte characters would complicate the mathematical operations
  # - Single-byte ensures consistent behavior across different Ruby versions/platforms
  #
  # @param input_str [String] The string to check
  # @return [Boolean] true if any character requires multiple bytes, false otherwise
  #
  # @rbs (String input_str) -> bool
  def contains_multibyte_chars?(input_str)
    input_str.each_char do |char|
      return true if char.bytesize > 1
    end

    false
  end

  # Rotates and reverses the alphabet based on an offset
  #
  # This transformation is a crucial part of the Sqids algorithm:
  # - Rotation: moves elements from the start to the end by 'offset' positions
  # - Reversal: reverses the entire array order
  #
  # These operations ensure that:
  # - Different input numbers produce different alphabet arrangements
  # - The transformation is deterministic and reproducible during decoding
  # - Sequential numbers don't produce predictable patterns
  #
  # Both encoder and decoder use this to synchronize their alphabet state.
  #
  # @param alphabet [Array<Integer>] The alphabet to transform (character codepoints)
  # @param offset [Integer] Number of positions to rotate
  # @return [Array<Integer>] A new rotated and reversed alphabet
  #
  # @example
  #   rotate_and_reverse_alphabet([1,2,3,4,5], 2)
  #   # => [5, 4, 1, 2, 3] (rotated by 2: [3,4,5,1,2], then reversed)
  #
  # @rbs (Array[Integer] alphabet, Integer offset) -> Array[Integer]
  def rotate_and_reverse_alphabet(alphabet, offset)
    rotated_alphabet = alphabet.dup
    rotated_alphabet.rotate!(offset)
    rotated_alphabet.reverse!
  end
end
