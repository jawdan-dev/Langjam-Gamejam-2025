// Hot Honey Loop Language.

enum HoneyConnection {
	SET,
	IF, JUMP, CALL, RETURN,
};

function HoneyNode(name) constructor {
	m_name = name;
	m_value = 0;
	m_connections = [];
	m_variables = [];
}

function HoneyNodeConnection(to, type, args = []) constructor {
	m_to = to;
	m_type = type;
	m_args = args;
}


function Honey(filePath = "") constructor {
	m_nodes = [];
	m_variables = [];
	m_functions = [];
	m_anonymousCounter = 0;
	
	function getShortScope(scope) {
		if (string_length(scope) <= 2) return scope;
		if (string_char_at(scope, 2) != ".") return scope;
		return string_copy(scope, 3, string_length(scope) - 2);
	}
	function getVariableName(name, scope = "") {
		if (string_char_at(name, 1) == "#") {
			return "G." + name;	
		}
		return "V." + getShortScope(scope) + name;	
	}
	function getFunctionName(name, scope = "") {
		return "F." + getShortScope(scope) + name;	
	}
	function getAnonymousName(scope = "") {
		return "A." + getShortScope(scope) + string(m_anonymousCounter++);	
	}
	function getErrorName(scope = "") {
		return "E." + getShortScope(scope) + string(m_anonymousCounter++);	
	}
	function getScope(scope, newScope) {
		if (newScope == "") return scope;
		return scope + newScope + ".";	
	}
	
	static getNode = function(name) {
		if (is_struct(name) && instanceof(name) == "HoneyNode")
			return name; 
		
		var nodeCount = array_length(m_nodes);
		for (var i = 0; i < nodeCount; i++) {
			if (m_nodes[i].m_name != name)
				continue;
			return m_nodes[i];
		}
		if (name == undefined) {
			name = getAnonymousName();
		} else if (!is_string(name)) {
			name = getErrorName();
		}
		var index = array_length(m_nodes);
		m_nodes[index] = new HoneyNode(name);
		return m_nodes[index];
	}
	static addConnection = function(from, to, type, args = []) {		
		var fromNode = getNode(from), 
			toNode = getNode(to);
		
		fromNode.m_connections[array_length(fromNode.m_connections)] = new HoneyNodeConnection(toNode, type, args);
		return toNode;
	}
	static addVariable = function(node, variable) {		
		node.m_variables[array_length(node.m_variables)] = getNode(variable);
	}

	static evaluate = function(args) {
		
	}
	static call = function(name, args = []) {
		function callNode(startNode) {
			var currentNode = startNode;
			do {
				var connectionCount = array_length(node.m_connections);
				for (var i = 0; i < connectionCount; i++) {
					switch (node.m_connections[i].m_type) {
						case HoneyConnection.SET: currentNode = node.m_connections[i].m_to; break;
						case HoneyConnection.IF: 
						
							evaluate();
							if (node.m_connections[i].m_args)
							currentNode = node.m_connections[i].m_to; 
							
						break;
						case HoneyConnection.JUMP: currentNode = node.m_connections[i].m_to; break;
						case HoneyConnection.CALL: break;
						case HoneyConnection.RETURN: currentNode = node.m_connections[i].m_to; break;
					}
				}
			} until (currentNode == startNode);
		}
		
		var functionName = getFunctionName(name, "");
		for (var i = 0; i < array_length(m_functions); i++) {
			if (m_functions[i].m_name != functionName) continue;
			callNode(m_functions[i]);
			break;
		}
	}
	static draw = function(x, y, w, h) {
		var nodeCount = array_length(m_nodes);
		
		var cx = x + (w * 0.5);
		var cy = y + (h * 0.5);
		var size = min(w, h) * 0.5;
		
		function getIndex(nodes, node) {
			var nodeCount = array_length(nodes);
			for (var i = 0; i < nodeCount; i++)
				if (nodes[i] == node) 
					return i;
			return -1;
		}
		
		var a = (pi * 2.0) / nodeCount;
		for (var i = 0; i < nodeCount; i++) {
			draw_set_color(c_white);
					
			var dx = cx + (sin(a * i) * size);
			var dy = cy + (-cos(a * i) * size);
			
			draw_circle(dx, dy, 8.0, true);
			draw_text(dx, dy, m_nodes[i].m_name);
			
			var connectionCount = array_length(m_nodes[i].m_connections);
			for (var c = 0; c < connectionCount; c++) {
				var to = m_nodes[i].m_connections[c].m_to;
				var toIndex = getIndex(m_nodes, to);
				
				switch (m_nodes[i].m_connections[c].m_type) {
					default: draw_set_color(c_white); break;
					case HoneyConnection.IF: draw_set_color(c_orange); break;
					case HoneyConnection.JUMP: draw_set_color(c_aqua); break;
					case HoneyConnection.SET: draw_set_color(c_green); break;
				}
				
				var tx = cx + (sin(a * toIndex) * size);
				var ty = cy + (-cos(a * toIndex) * size);
				draw_line(dx, dy, tx, ty);
				
				var rx = (tx - dx) * 0.1;
				var ry = (ty - dy) * 0.1;
				draw_circle(tx - rx, ty - ry, 3.0, false);
			}
		}
	}
	
	static parseCode = function(code, scope = "", topScope = false) {
		code = string_trim(code, [ " " ]);
		
		var keywordIndex = string_pos(" ", code);
		var keyword = keywordIndex != 0 ? string_copy(code, 1, keywordIndex - 1) : code;
				function breakDownValue(value, scope) {
			function getSymbols(valueString, valueStart, valueEnd, scope) {
				var symbols = [];
				
				var currentSymbol = "";
				enum SymbolType {
					Value,
					Variable,
					Symbol,
				}
				var type = SymbolType.Variable;
				
				function isVariable(char) {
					return string_pos(char, "#qwertyuiopasdfghjklzxcvbnm") > 0;
				}
				function isNumber(char) {
					return string_pos(char, "1234567890") > 0;
				}
				function isSymbol(char) {
					return string_pos(char, "+-/*<>=") > 0;
				}

				for (var i = valueStart; i < valueEnd; i++) {
					var char = string_char_at(valueString, i + 1);
					
					if (string_length(currentSymbol) <= 0) {
						currentSymbol = char;	
						if (isVariable(char)) {
							type = SymbolType.Variable;
						} else if (isNumber(char)) {
							type = SymbolType.Value;
						} else if (isSymbol(char)) {
							type = SymbolType.Symbol;
						} else if (char == "(") {
							var scopeStart = i + 1;
							var scopeDepth = 1;
							i++;
							while (i < valueEnd && scopeDepth > 0) {
								switch (string_char_at(valueString, i + 1)) {
									case "(": scopeDepth++; break;	
									case ")": scopeDepth--; break;	
								}
								i++;
							}
							var scopeEnd = i;
							var scopeSymbols = getSymbols(valueString, scopeStart, scopeEnd, scope);
							symbols[array_length(symbols)] = scopeSymbols;
							
							currentSymbol = "";
						} else {
							currentSymbol = "";
						}
						continue;
					} 
					
					var valueFound = false;
					switch (type) {
						case SymbolType.Variable: {
							if (isVariable(char) || isNumber(char)) {
								currentSymbol += char;
							} else if (char == "(") {
								currentSymbol = getFunctionName(currentSymbol, "");
								symbols[array_length(symbols)] = currentSymbol;
								currentSymbol = "@";
								valueFound = true;
							} else {
								currentSymbol = getVariableName(currentSymbol, scope);
								valueFound = true;
							}
						} break;
						case SymbolType.Value: {
							if (isNumber(char)) {
								currentSymbol += char;
							} else {
								valueFound = true;
							}
						} break;
						case SymbolType.Symbol: {
							if (isSymbol(char)) {
								currentSymbol += char;
							} else {
								valueFound = true;
							}
						} break;
					}
					if (!valueFound ) continue;
					
					symbols[array_length(symbols)] = currentSymbol;
					currentSymbol = "";
					i--;	
				}
				
				if (string_length(currentSymbol) > 0) {
					symbols[array_length(symbols)] = currentSymbol;
				}
				
				var sortedSymbols = [];
				for (var i = 0; i < array_length(symbols); i++) {
					var symbol = symbols[i];
					if (i % 2 == 1) {
						// Symbol assumed. TODO: Not this lol...
						if (!is_string(symbol) || (!isSymbol(string_char_at(symbol, 1)) && symbol != "@")) {
							throw(string(symbol) + " is not a functional symbol");	
						}
						
						var currentIndex = array_length(sortedSymbols) - 1;
						var temp = sortedSymbols[currentIndex];
						sortedSymbols[currentIndex] = symbol;
						sortedSymbols[array_length(sortedSymbols)] = temp;
					} else {
						// Somin else.
						sortedSymbols[array_length(sortedSymbols)] = symbol;
					}
				}
				symbols = []; // Expanded symbols.
				for (var i = 0; i < array_length(sortedSymbols); i++) {
					var symbol = sortedSymbols[i];
					if (!is_array(symbol)) { 
						symbols[array_length(symbols)] = symbol;
						continue;
					}
					for (var j = 0; j < array_length(symbol); j++) {
						symbols[array_length(symbols)] = symbol[j];
					}
				}
				
				show_debug_message(symbols);
				return symbols;
			}		
			return getSymbols(value, 0, string_length(value), scope);
			
			// symbols 
			// variables
			// values
			// functions(...)
		}
		
		function readFormat(source, formatString, scope) {			
			var sourceIndex = 0, formatIndex = 0;
			var result = [];
			
			while (formatIndex < string_length(formatString)) {			
				var formatChar = string_char_at(formatString, formatIndex + 1);
				switch (formatChar) {
					case "%": {
						formatIndex++;
						var typeStart = formatIndex;
						while (string_char_at(formatString, formatIndex + 1) != "%")
							formatIndex++;
						var typeEnd = formatIndex;
						
						var type = string_copy(formatString, typeStart + 1, typeEnd - typeStart);
						
						if (type == "condition") 
							type = "val";
						
						switch (type) {
							default: { 
								show_debug_message("UNHANDLED FORMAT TYPE " + type);
								return undefined; 
							}
							
							case "var":
							case "val":
							case "csv":
							case "condition": {
								var allowedCharacters = "";
								switch (type) {
									case "var": allowedCharacters = "#qwertyuiopasdfghjklzxcvbnm1234567890"; break;
									case "val": allowedCharacters = " 1234567890.#qwertyuiopasdfghjklzxcvbnm+-/*()"; break;
									case "csv": allowedCharacters = " qwertyuiopasdfghjklzxcvbnm,"; break;
									case "condition": allowedCharacters = " 1234567890.#qwertyuiopasdfghjklzxcvbnm=<>+-/*()"; break;
								}
								var contentStart = sourceIndex;
								var contentDepth = 1;
								while (string_pos(string_char_at(source, sourceIndex + 1), allowedCharacters) != 0 && contentDepth > 0) {
									if (sourceIndex >= string_length(source)) 
										return undefined;
									switch (string_char_at(source, sourceIndex + 1)) {
										case "(": contentDepth++; break;
										case ")": contentDepth--; break;
									}
									if (contentDepth <= 0) sourceIndex--;
									sourceIndex++;
								}
								var contentEnd = sourceIndex;
								var content = string_copy(source, contentStart + 1, contentEnd - contentStart);
								
								switch (type) {
									case "val": {
										content = breakDownValue(content, scope);
									} break;
									case "csv": {
										content = string_split(content, ",", true);
										for (var i = 0; i < array_length(content); i++) {
											content[i] = string_trim(content[i], [ " " ]);	
										}
									} break;
								}
								
								result[array_length(result)] = content
							} break;
							
							case "block": {
								if (string_char_at(source, sourceIndex + 1) == "{") {
									sourceIndex++;
									var sourceDepth = 1;
									var contentStart = sourceIndex;
									while (sourceDepth > 0) {
										if (sourceIndex >= string_length(source)) 
											return undefined;
										switch (string_char_at(source, sourceIndex + 1)) {
											case "{": sourceDepth++; break;
											case "}": sourceDepth--; break;
										}
										sourceIndex++;
									}					
									var contentEnd = sourceIndex - 1;
									var content = string_copy(source, contentStart + 1, contentEnd - contentStart);	
									result[array_length(result)] = content;
								} else {
									var contentStart = sourceIndex;
									while (string_char_at(source, sourceIndex + 1) != ";" && sourceIndex < string_length(source)) {
										sourceIndex++;
									}		
									var contentEnd = ++sourceIndex;
									var content = string_copy(source, contentStart + 1, contentEnd - contentStart);
									result[array_length(result)] = content;
								}
							} break;
						}
					} break;
					case "*": {
						result[array_length(result)] = string_copy(source, sourceIndex + 1, string_length(source) - sourceIndex);
					} break;
					
					default: {
						if (string_char_at(source, sourceIndex + 1) != formatChar) 
							return undefined;
						sourceIndex++;
					} break;
				}
				formatIndex++;
			}
			
			return result;
		}
		
		var nodes = {
			m_first: undefined,
			m_last: undefined,
			m_keyword: keyword,
		};
		
		function getLastNode(nodes) {
			if (nodes.m_last == undefined)
				return appendNode(nodes, getNode(undefined));
			return nodes.m_last;
		}
		function appendNode(nodes, node) {
			if (node == undefined) return;
			if (nodes.m_first == undefined)
				nodes.m_first = node
			nodes.m_last = node;
			return nodes.m_last;
		}
		function removeNode(node) {
			var nodeCount = array_length(m_nodes);
			for (var i = 0; i < nodeCount; i++) {
				if (m_nodes[i] != node) continue;
				array_delete(m_nodes, i, 1);				
				break;
			}
			delete node;
		}
		function mergeNodes(nodes, tracking, topScope) {
			if (topScope) return;
			if (tracking.m_first == undefined) return;
			for (var i = 0; i < array_length(tracking.m_first.m_connections); i++) {
				if (tracking.m_first.m_connections[i].m_to == tracking.m_first) {
					tracking.m_first.m_connections[i].m_to = nodes.m_last;
				}
			}
			nodes.m_last.m_connections = array_concat(nodes.m_last.m_connections, tracking.m_first.m_connections);
			removeNode(tracking.m_first);
			nodes.m_last = tracking.m_last;
		}
		function firstConnectionTo(node) {
			for (var n = 0; n < array_length(m_nodes); n++) {
				for (var c = 0; c < array_length(m_nodes[n].m_connections); c++) {
					if (m_nodes[n].m_connections[c].m_to == node)
						return m_nodes[n].m_connections[c];
				}
			}
			return undefined;
		}
		
		switch (keyword) {
			default: { 
				var data;
				
				// Statement.
				data = readFormat(code, "%var% = %val%;*", scope);
				if (data != undefined) {
					appendNode(nodes, addConnection(getLastNode(nodes), undefined, HoneyConnection.SET, [ data[0], data[1] ]));
					mergeNodes(nodes, parseCode(data[2], scope), topScope);
					break;
				}
				
				// Unhandled.
				show_debug_message("UNHANDLED KEYWORD " + keyword);
			} break;
			
			case "": break;
							
			case "fn": {
				var data = readFormat(code, "fn %var%(%csv%) %block%*", scope);
				if (data == undefined) return;
				
				var functionName = getFunctionName(data[0], scope),
					functionArgs = data[1],
					functionCode = data[2];
				
				var functionNode = getNode(functionName);
				var functionScope = getScope(scope, functionName);
				
				functionNode.m_args = functionArgs; 
				for (var i = 0; i < array_length(functionNode.m_args ); i++) {
					functionNode.m_args[i] = getVariableName(functionNode.m_args [i], functionScope);
				}
				m_functions[array_length(m_functions)] = functionNode;
				
				appendNode(nodes, functionNode);
				mergeNodes(nodes, parseCode(functionCode, functionScope), false);
				if (nodes.m_last != functionNode)
					addConnection(nodes.m_last, functionNode, HoneyConnection.JUMP);	

				mergeNodes(nodes, parseCode(data[3], scope, topScope), topScope);
			} break;
			
			case "if": {
				var data = readFormat(code, "if (%condition%) %block%*", scope);
				if (data == undefined) return;

				var ifCondition = data[0],
					ifCode = data[1],
					nextCode = data[2];

				var rootNode = getLastNode(nodes);
				var codeNodes = parseCode(ifCode, scope);				
				addConnection(rootNode, codeNodes.m_first, HoneyConnection.IF, [ ifCondition ]);
				appendNode(nodes, codeNodes.m_last);
				
				var jumps = [ rootNode ]; 
				var ends = [ codeNodes.m_last ]; 
				while (string_length(nextCode) > 0) {
					var next = parseCode(nextCode, scope, topScope);
					switch (next.m_keyword) {
						default: {
							for (var i = 0; i < array_length(jumps); i++)
								appendNode(nodes, addConnection(jumps[i], next.m_first, HoneyConnection.JUMP));
							for (var i = 0; i < array_length(ends); i++) {
								var connection = firstConnectionTo(ends[i]);
								if (connection == undefined) continue;
								removeNode(connection.m_to);
								connection.m_to = next.m_first;
							}
							appendNode(nodes, next.m_last);
							nextCode = ""; 
						} break;
						case "elif": {
							var block = parseCode(next.m_ifCode, scope);
							appendNode(addConnection(rootNode, block.m_first, HoneyConnection.IF, [ next.m_ifCondition ]));
							nextCode = next.m_nextCode;
							ends[array_length(ends)] = block.m_last;
						} break;
						case "else": {
							var block = parseCode(next.m_ifCode, scope);
							appendNode(nodes, addConnection(rootNode, block.m_first, HoneyConnection.JUMP));
							nextCode = next.m_nextCode;
							jumps = [];
							ends[array_length(ends)] = block.m_last;
						} break;
					}
				}
			} break;
			case "elif": {
				var data = readFormat(code, "elif (%condition%) %block%*", scope);
				if (data == undefined) return;

				var ifCondition = data[0],
					ifCode = data[1],
					nextCode = data[2];
				
				return {
					m_keyword: nodes.m_keyword,
					m_ifCondition: ifCondition,
					m_ifCode: ifCode,
					m_nextCode: nextCode,
				};
			}
			case "else": {
				var data = readFormat(code, "else %block%*", scope);
				if (data == undefined) return;

				var ifCode = data[0],
					nextCode = data[1];
					
				return {
					m_keyword: nodes.m_keyword,
					m_ifCode: ifCode,
					m_nextCode: nextCode,
				};
			}
			
			case "for":{
				var data = readFormat(code, "for %var%(%val%, %val%) %block%*", scope);
				if (data == undefined) return;

				var forVar = getScope(data[0], getLastNode(nodes).m_name),
					forFrom = data[1],
					forTo = data[2],
					forCode = data[3];
				
				// TODO: Polarity.
				var forNode = appendNode(nodes, addConnection(getLastNode(nodes), undefined, HoneyConnection.SET, array_concat([ forVar ], forFrom)));
				appendNode(nodes, addConnection(forNode, undefined, HoneyConnection.IF, array_concat([ "<", forVar ], forTo)));
				mergeNodes(nodes, parseCode(forCode, scope), false);
				appendNode(nodes, addConnection(getLastNode(nodes), undefined, HoneyConnection.SET, [ forVar, forVar + " + 1" ]));
				addConnection(getLastNode(nodes), forNode, HoneyConnection.JUMP);
				nodes.m_last = forNode;
				mergeNodes(nodes, parseCode(data[4], scope, topScope), topScope);
			} break;
			
			case "return":{
				var data = readFormat(code, "return %val%;*", scope);
				if (data == undefined) return;
				appendNode(nodes, addConnection(getLastNode(nodes), getLastNode(nodes), HoneyConnection.RETURN, [ data[0] ]));
			} break;
		}
		
		return nodes;
	}
	
	// Actually loading the code:
	if (filePath == "") return;
	var file = file_text_open_read(filePath)
	
	var fileContents = "";
	while (!file_text_eof(file)) {
		fileContents  += file_text_readln(file);
	}
	fileContents = string_replace_all(fileContents, "\n", " ");
	fileContents = string_replace_all(fileContents, "\r", "");
	fileContents = string_replace_all(fileContents, "\t", "");
	fileContents = string_replace_all(fileContents, "  ", " ");
	parseCode(fileContents, "", true);
	
	file_text_close(file);
}