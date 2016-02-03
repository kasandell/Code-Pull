if !has('python')
	finish
endif

command! -nargs=1 Pull call PullCode(<f-args>)
function! PullCode(description)


python <<_EOF_

import json
import requests
import vim

class CodeRetriever:


	def __init__(self, initKeywords, language):
		"""Initialize the class with keywords and language"""
		self.keywords = initKeywords
		language_codes = {'javascript': 22,
			'swift':137,
			'python':19,
			'c': 28,
			'java':23,
			'php':24,
			'cpp':16,
			'lisp':29,
			'html':3,
			'header':15,
			'ruby':32,
			'perl':51,
			'vimscript':33,
			'haskell':40,
			'scala':47,
			'markdown':118,
			'pascal':46,
			'erlang':25,
			'actionscript':42,
			'lua':54,
			'go':55,
			'objective-c':21,
			'json':122,
			'd':45,
			'config':113,
			'ocaml':64,
			'coffeescript':106,
			'matlab':20,
			'assembly':34,
			'typescript':151}
		self.language = language_codes[language] #  this will be determined from the ending of the file
		#print self.language

	def removeCommentOnlyCode(self, codeGroups):

		def isComment(line):
			return line[0] in '#\'"' or line.startswith('//')

		def hasComments(group):
			return any([isComment(line) for line in group.splitlines()])

		return [g for g in codeGroups if not hasComments(g)]



	def pickMostLikelyCode(self, lineSegments, code):
		"""Get the groupings of lines that are returned

		Here we look for code that:

			a) does shit(we don't want method declarations and all that shit, we want code)
			b) seems to do the right thing (methods that are named similar to keywords)
			TODO: implement an algorithm that finds other ways to predict if code does the right thing
		"""
		def wanted(word):
			#list of general programming terms we don't want included
			unwanted = ['string', 'int', 'double', 'float', 'bool', 'boolean', 'char', 'integer']
			return word.lower() not in unwanted

		#delete all general terms from the keywords
		self.keywords = [w for w in self.keywords if wanted(w)]

		#compile the lines into code segments
		codeGroups = []
		for lineSegment in lineSegments:
			codeLine = '\n'.join([code[str(s)] for s in lineSegment])
			codeGroups.append(codeLine)
		codeGroups = self.removeCommentOnlyCode(codeGroups)
		highestKeywords = []
		keywordCount = 0
		#find the code segment that best matches our needs, based on keywords found in the code
		for segment in codeGroups:
			for word in self.keywords:
				keywordCount = keywordCount + segment.count(word)
			highestKeywords.append(keywordCount)
			keywordCount = 0
		wantedCode = highestKeywords.index(max(highestKeywords))
		return codeGroups[wantedCode]

	def querySearchCode(self):
		"""Scrape and grab code from github"""

		params = '+'.join(self.keywords)
		#params += self.language
		query = 'https://searchcode.com/api/codesearch_I/'#?q=reverse+string&lan=19'
		q = {'q':params,
			'lan':self.language}#for testing purposes, make this python. Will add a dict later that has language to number mappings
		param_str = '&'.join('%s=%s' %(k, v) for k,v in q.items())
		param_str = param_str.replace(' ', '+')

		#request the data from the page, and then we will pull the code out? or open the file to the location and pull out from start to end braces/ indent?
		page = requests.get(query, params = param_str)
		js = json.loads(page.content)
		firstCodeSet = js['results'][0]['lines']
		lineGroups = self.getLineGroups(firstCodeSet)
		#extract section of html containing top answer
		finCode = self.pickMostLikelyCode(lineGroups, firstCodeSet)
		return finCode
		#if we did, follow the link to the code, and extract the entire method that is there


	def getLineGroups(self, lineDict):
		lineNumbers = [int(k) for k in lineDict.keys()]
		result = []
		segment = []
		lineNumbers.sort()
		#until the list is empty
		while lineNumbers:
			#get the minimum line number
			firstLine = min(lineNumbers)
			lineNumbers.remove(firstLine)
			#if this is the first line ever, just put it in
			if segment and firstLine != int(max(segment))+1:
				#it belongs in a new group, so finalize the old group, and start a new one
				result.append(segment)
				segment = []
			segment.append(firstLine)
		result.append(segment)
		return result


args = vim.eval("a:description")

argsDict = args.split(' ')

vim.command("let r = &filetype")


ftype = vim.eval("r")


cr = CodeRetriever(argsDict, ftype)

fin = cr.querySearchCode()

codeArr = fin.splitlines()
vim.command("let ret = \"%s\"" %fin)

_EOF_


let codeArr = split(ret, "\n")
let codeArrReverse = reverse(codeArr)
for i in codeArrReverse
	call append('.', i)
endfor

endfunction
