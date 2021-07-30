meta:
  id: rgblink
  file-extension: o
  endian: le
  bit-endian: le
seq:
  - id: id
    contents: 'RGB9'
  - id: revision_number
    contents: [8, 0, 0, 0]
    doc: The format's revision number this file uses.
  - id: number_of_symbols
    type: s4
    doc: The number of symbols used in this file.
  - id: number_of_sections
    type: s4
    doc: The number of sections used in this file.
  - id: number_of_nodes
    type: s4
    doc: The number of nodes contained in this file.
  - id: nodes
    type: node
    repeat: expr
    repeat-expr: number_of_nodes
    doc: |
      IMPORTANT NOTE: the nodes are actually written in
      **reverse** order, meaning the node with ID 0 is
      the last one in the file!
  - id: symbols
    type: symbol
    repeat: expr
    repeat-expr: number_of_symbols
  - id: sections
    type: section
    repeat: expr
    repeat-expr: number_of_sections
  - id: number_of_assertions
    type: s4
  - id: assertions
    type: assertion
    repeat: expr
    repeat-expr: number_of_assertions
types:
  node:
    seq:
      - id: parent_id
        type: s4
        doc: ID of the parent node, -1 means this is the root.
      - id: parent_line_no
        type: s4
        doc: |
          Line at which the parent context was exited.
          Meaningless on the root node.
      - id: type
        type: u1
        enum: node_type
      - id: name
        type: str
        terminator: 0
        encoding: ASCII
        if: type != node_type::rept
        doc: |
          The node's name: either a file name, or macro name
          prefixed by its definition file name.
      - id: depth
        type: s4
        if: type == node_type::rept
        doc: Size of the array below.
      - id: iter
        type: s4
        repeat: expr
        repeat-expr: depth
        if: type == node_type::rept
        doc: |
          The number of REPT iterations by increasing depth.
          If the node is a REPT, it also contains the iter
          counts of all the parent REPTs.
  symbol:
    seq:
      - id: name
        type: str
        terminator: 0
        encoding: ASCII
        doc: |
          The name of this symbol. Local symbols are stored
          as "Scope.Symbol".
      - id: type
        type: u1
        enum: symbol_type
      - id: source_file
        type: s4
        if: type != symbol_type::import
        doc: File where the symbol is defined.
      - id: line_num
        type: s4
        if: type != symbol_type::import
        doc: Line number in the file where the symbol is defined.
      - id: section_id
        type: s4
        if: type != symbol_type::import
        doc: |
          The section number (of this object file) in which
          this symbol is defined. If it doesn't belong to any
          specific section (like a constant), this field has
          the value -1.
      - id: value
        type: s4
        if: type != symbol_type::import
        doc: |
          The symbols value. It's the offset into that
          symbol's section.
  section:
    seq:
      - id: name
        type: str
        terminator: 0
        encoding: ASCII
        doc: Name of the section
      - id: size
        type: s4
        doc: Size in bytes of this section
      - id: type
        type: b6
        enum: section_type
      - id: fragment
        type: b1
        doc: Mutually exclusive with unionized flag.
      - id: unionized
        type: b1
        doc: Mutually exclusive with fragment flag.
      - id: org
        type: s4
        doc: |
          Address to fix this section at. -1 if the linker should
          decide (floating address).
      - id: bank
        type: s4
        doc: |
          Bank to load this section into. -1 if the linker should
          decide (floating bank). This field is only valid for ROMX,
          VRAM, WRAMX and SRAM sections.
      - id: align
        type: u1
        doc: Alignment of this section, as N bits. 0 when not specified.
      - id: ofs
        type: s4
        doc: |
          Offset relative to the alignment specified above.
          Must be below 1 << Align.
      - id: data
        type: u1
        repeat: expr
        repeat-expr: size
        if: type == section_type::romx or type == section_type::rom0
        doc: Raw data of the section.
      - id: number_of_patches
        type: s4
        if: type == section_type::romx or type == section_type::rom0
        doc: Number of patches to apply.
      - id: patches
        type: patch
        repeat: expr
        repeat-expr: number_of_patches
        if: type == section_type::romx or type == section_type::rom0
  patch:
    seq:
      - id: source_file
        type: s4
        doc: |
          ID of the source file node (for printing
          error messages).
      - id: line_no
        type: s4
        doc: Line at which the patch was created.
      - id: offset
        type: s4
        doc: |
          Offset into the section where patch should
          be applied (in bytes).
      - id: pc_section_id
        type: s4
        doc: |
          Index within the file of the section in which
          PC is located.
          This is usually the same section that the
          patch should be applied into, except e.g.
          with LOAD blocks.
      - id: pc_offset
        type: s4
        doc: |
          PC's offset into the above section.
          Used because the section may be floating, so
          PC's value is not known to RGBASM.
      - id: type
        type: u1
        enum: patch_type
      - id: rpn_size
        type: s4
        doc: |
          Size of the buffer with the RPN.
          expression.
      - id: rpn
        type: rpn
        size: rpn_size
        doc: RPN expression.
  assertion:
    seq:
      - id: source_file
        type: s4
        doc: ID of the source file node (for printing the failure).)
      - id: line_no
        type: s4
        doc: Line at which the assertion was created.
      - id: offset
        type: s4
        doc: Offset into the section where the assertion is located.
      - id: section_id
        type: s4
        doc: |
          Index within the file of the section in which PC is
          located, or -1 if defined outside a section.
      - id: pc_offset
        type: s4
        doc: |
          PC's offset into the above section.
          Used because the section may be floating, so PC's value
          is not known to RGBASM.
      - id: type
        type: u1
        enum: assertion_type
      - id: rpn_size
        type: s4
        doc: Size of the RPN expression's buffer.
      - id: rpn
        type: rpn
        size: rpn_size
        doc: RPN expression, same as patches. Assert fails if == 0.
      - id: message
        type: str
        terminator: 0
        encoding: ASCII
        doc: |
          A message displayed when the assert fails. If set to
          the empty string, a generic message is printed instead.
  rpn:
    seq:
      - id: entries
        type: rpn_entry
        repeat: eos
  rpn_entry:
    seq:
      - id: operator
        type: u1
        enum: rpn_operator
      - id: symbol_id
        type: s4
        if: |
          operator == rpn_operator::bank_symbol or
          operator == rpn_operator::symbol
      - id: section_name
        type: str
        terminator: 0
        encoding: ASCII
        if: |
          operator == rpn_operator::bank_section or
          operator == rpn_operator::sizeof_section or
          operator == rpn_operator::startof_section
      - id: int
        type: s4
        if: operator == rpn_operator::int
enums:
  node_type:
    0: rept
    1: file
    2: macro
  symbol_type:
    0: local
    1: import
    2: export
  section_type:
    0: wram0
    1: vram
    2: romx
    3: rom0
    4: hram
    5: wramx
    6: sram
    7: oam
  patch_type:
    0: byte
    1: word
    2: long
    3: jr_offset
  assertion_type:
    0: print # Prints the message but allows linking to continue
    1: error # Prints the message and evaluates other assertions,
             # but linking fails afterwards
    2: abort # Prints the message and immediately fails linking
  rpn_operator:
    0x00: add
    0x01: subtract
    0x02: multiply
    0x03: divide
    0x04: modulo
    0x05: negative
    0x06: power
    0x10: bitwise_or
    0x11: bitwise_and
    0x12: bitwise_xor
    0x13: negate
    0x21: logical_and
    0x22: logical_or
    0x23: not
    0x30: equal
    0x31: not_equal
    0x32: greater_than
    0x33: less_than
    0x34: greater_than_or_equal
    0x35: less_than_or_equal
    0x40: left_shift
    0x41: right_shift
    0x50: bank_symbol # + LONG symbol_id, where -1 means PC
    0x51: bank_section # + STR section_name
    0x52: current_bank
    0x53: sizeof_section # + STR section_name
    0x54: startof_section # + STR section_name
    0x60: hram_check # Checks if the value is in HRAM, ANDs it with 0xFF.
    0x61: rst_check # Checks if the value is a RST vector, ORs it with 0xC7.
    0x80: int # + LONG int
    0x81: symbol # + LONG symbol_id
