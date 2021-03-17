#!/usr/bin/ruby
# coding: utf-8

class Base_Character
	attr_accessor :char, :grader
	def initialize(character)
		@char = character
		@grader = ""
	end

	def get_width_on_term
		charcode = @char.unpack("H*")[0].hex
		if (0xe2ba80 <= charcode && charcode <= 0xe9bea0) || (0xefa480 <= charcode && charcode <= 0xefa9ad) || (0xefbc80 <= charcode && charcode <= 0xefbda0)  || (0xefbfa0 <= charcode && charcode <= 0xefbfa6)
			return 2 
		else
			return 1
		end
	end

	def is_kana
		charcode = @char.unpack("H*")[0].hex
		if (0xe38181 <= charcode && charcode <= 0xe383ba)
			return true
		end
		return false
	end
end

class Base_Word
	attr_accessor :yomi, :characters_data, :category, :grader, :category_table_msime
	def initialize
		@yomi = ""
		@characters_data = []
		@category = ""
		@grader = ""

		@category_table_msime = {
			"サ行(する)"=>"さ変名詞",
			"ザ行(ずる)"=>"ざ変名詞",
			"サ行(する)&名詞"=>"さ変名詞",
			"ザ行(ずる)&名詞"=>"ざ変名詞",
			"形容動詞(たる)"=>"形容動詞",
			"形容動詞&名詞"=>"形動名詞",
			"ア行五段"=>"あわ行五段",
			"カ行五段"=>"か行五段",
			"ガ行五段"=>"が行五段",
			"サ行五段"=>"さ行五段",
			"タ行五段"=>"た行五段",
			"ナ行五段"=>"な行五段",
			"バ行五段"=>"ば行五段",
			"マ行五段"=>"ま行五段",
			"ラ行五段"=>"ら行五段",
			"ワ行五段"=>"あわ行五段",
			"一段"=>"一段動詞",
			"一段&名詞"=>"一段動詞", 
			"一動幹"=>"一段動詞", 
			"数詞"=>"助数詞", 
			"接頭語(各)"=>"接頭語", 
			"単漢字"=>"名詞",
			"接続詞,感動詞"=>"接続詞", 
			"地名"=>"地名その他" 
		}
	end

	def characters
		word = ""
		@characters_data.each { |c| word += c.char }
		return word
	end
		
	def to_word_define(im)
		define = @yomi + "	" + characters
		case im
		when "msime"
			if @category_table_msime.has_key?(@category) then define += "	" + @category_table_msime[@category] else define += "	" + @category end
		else
			define += "	" + @category 
		end
		define += "	"
		if "" != @grader then define += "#" + @grader end
		return define
	end

	def length_by_width # total width of characters on terminal
		length = 0
		@characters_data.each { |c| length += c.get_width_on_term }
		return length
	end
end

class Base_Dict
	attr_accessor :word_list
	@@base_dict_file = "assets/kihon.u"
	def initialize
		@word_list = []
		base_dict = File.open(@@base_dict_file, mode="rb:euc-jp:utf-8")
		until base_dict.eof?
			line = base_dict.gets()
			word_define = line.split(" ")[0...3]
			word = Base_Word.new
			word.yomi = word_define[0]
			word_define[1].each_char { |c| word.characters_data.push(Base_Character.new(c)) }
			word.category = word_define[2]
			word.grader = ''
			@word_list.push(word)
		end
		base_dict.close
	end

	def get_list
		return @word_list
	end

	def show
		for word in get_list
			if word.character.length == 1
				STDERR.print word.yomi + " "
				STDERR.print word.character + "\n"
			end
		end
	end
end	

class Dict_Writer
	def write(word_list)
		write_handle = File.open("dict-utf8.txt", mode="wb:utf-8")
		for word in word_list
			write_handle.write(word.to_word_define(false)+"\r\n")
		end
		write_handle.close
	end

	def write_msime(word_list)
		dict_prefix = "dict"
		dict_profix = "-msime"
		dict_index = {
			"あ"=>/[あ-おア-オヴ]/,
			"か"=>/[か-こが-ごカ-コガ-ゴ]/,
			"さ"=>/[さ-そざ-ぞサ-ソザ-ゾ]/,
			"た"=>/[た-とだ-どタ-トダ-ド]/,
			"な"=>/[な-のナ-ノ]/,
			"は"=>/[は-ほば-ぼぱ-ぽハ-ホバ-ボパ-ポ]/,
			"ま"=>/[ま-もマ-モ]/,
			"や"=>/[や-よヤ-ヨ]/,
			"ら"=>/[ら-ろラ-ロ]/,
			"わ"=>/[わ-んワ-ン]/
		}
		dict_index.each_key { |index|
			write_handle = File.open(dict_prefix + "-" + index + dict_profix + ".txt", mode="wb:utf-16le")
			write_handle.write "\uFEFF"  # BOMを出力
			for word in word_list
				if dict_index[index].match?(word.yomi[0])
					write_handle.write(word.to_word_define("msime")+"\r\n")
				end
			end
			write_handle.close
		}
	end
end

class Gakunen_Kanji_Table
	@@gakunen_roman_list = {"ichi"=>"小学第一学年", "ni"=>"小学第二学年", "san"=>"小学第三学年", "yon"=>"小学第四学年", "go"=>"小学第五学年", "roku"=>"小学第六学年"}
	@@gakunen_kanji_table = {}

	def initialize
		@@gakunen_roman_list.keys.each { |gakunen_key|
			gakunen_kanji_list_file = File.open("data/dai-"+gakunen_key+"-gakunen.txt", mode="rb:utf-8")
			kanji_list = gakunen_kanji_list_file.gets().chomp().split("　")
			gakunen_kanji_list_file.close
			@@gakunen_kanji_table[gakunen_key] = kanji_list
		}
	end

	def get_gakunen_list
		return @@gakunen_roman_list.keys
	end

	def get_list(gakunen_roman_key)
		if @@gakunen_roman_list.include?(gakunen_roman_key)
			gakunen_kanji_text = File.open("data/dai-"+gakunen_roman_key+"-gakunen.txt", mode="rb:utf-8")
			kanji_list = gakunen_kanji_text.gets().chomp().split("　")
			gakunen_kanji_text.close
			return kanji_list
		end
	end

	def get_gakunen_name(gakunen_key)
		return @@gakunen_roman_list[gakunen_key]
	end

	def get_grader_by_character(char)
		@@gakunen_kanji_table.each_pair { |gakunen_key, kanji_list|
			if kanji_list.include?(char) then return get_gakunen_name(gakunen_key) end
		}
		return ""
	end

	def get_max_gakunen(base_word)
		max_gakunen_index = -1 
		base_word.characters_data.each { |char|
			if char.is_kana then next end
			if "" == char.grader then base_word.grader = ""; break end
			gakunen_index = @@gakunen_roman_list.find_index { |_,value| value == char.grader }
			if max_gakunen_index < gakunen_index then max_gakunen_index = gakunen_index; base_word.grader = char.grader end
		}
	end
end	

base_dict = Base_Dict.new
word_list = base_dict.get_list
gakunen_kanji_table = Gakunen_Kanji_Table.new
word_list.each { |word|
	word.characters_data.each { |char|
		char.grader = gakunen_kanji_table.get_grader_by_character(char.char)
		if "" == char.grader then next end
	}
	gakunen_kanji_table.get_max_gakunen(word)
	if "" == word.grader
		print "!" + word.characters + "\n"
	else 
		print word.characters + "..." + word.grader + "\n"
	end
}

dict_writer = Dict_Writer.new
dict_writer.write(word_list)
dict_writer.write_msime(word_list)

STDERR.print "完了しました。"
STDERR.print "\n"
