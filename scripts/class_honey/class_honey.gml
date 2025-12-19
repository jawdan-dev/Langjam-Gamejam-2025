// Hot Honey Loop Language.

enum HoneyConnection {
	SET,
	IF, JUMP, CALL, RETURN,
};

function HoneyNode(name) constructor {
	m_name = name;
	m_value = 0;
	m_connections = [];
}

function HoneyNodeConnection(to, type, args = []) constructor {
	m_to = to;
	m_type = type;
	m_args = args;
	m_variables = [];
}

function Honey(filePath = "") constructor {
	m_nodes = [];
	m_variables = [];
	m_functions = [];
	m_anonymousCounter = 0;
	
	function isVariable(char) {
		return string_pos(char, "#qwertyuiopasdfghjklzxcvbnm") > 0;
	}
	function isNumber(char) {
		return string_pos(char, "1234567890") > 0;
	}
	function isSymbol(char) {
		return string_pos(char, "+-/*<>=,") > 0;
	}
	
	function getShortScope(scope) {
		if (string_length(scope) <= 2) return scope;
		if (string_char_at(scope, 2) != ".") return scope;
		return string_copy(scope, 3, string_length(scope) - 2);
	}
	function isVariableName(name) {
		return string_char_at(name, 1) == "V";
	}
	function getVariableName(name, scope = "") {
		if (string_char_at(name, 1) == "#") {
			return "G." + name;	
		}
		return "V." + getShortScope(scope) + name;	
	}
	function isFunctionName(name) {
		return string_char_at(name, 1) == "F"
	}
	function getFunctionName(name, scope = "") {
		return "F." + getShortScope(scope) + getShortScope(name);	
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
	
	static getNode = function(name, moveToBack = false) {
		var found = undefined;
		var foundIndex = -1;
		if (is_struct(name) && instanceof(name) == "HoneyNode")
			found = name; 
		
		if (found == undefined) {
			var nodeCount = array_length(m_nodes);
			for (var i = 0; i < nodeCount; i++) {
				if (m_nodes[i].m_name != name)
					continue;
				found = m_nodes[i];
				foundIndex = i;
				break;
			}
		} else if (moveToBack) {
			var nodeCount = array_length(m_nodes);
			for (var i = 0; i < nodeCount; i++) {
				if (m_nodes[i] != found)
					continue;
				foundIndex = i;
				break;
			}
		}
		
		if (found != undefined) {
			if (moveToBack && foundIndex != -1) {
				// AESTHETIC.
				array_delete(m_nodes, foundIndex, 1);
				m_nodes[array_length(m_nodes)] = found;
			}
			return found;
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
		
		var connection = new HoneyNodeConnection(toNode, type, args);
		fromNode.m_connections[array_length(fromNode.m_connections)] = connection;
		
		function addVariableConnections(connection, variables) {
			var variableCount = array_length(variables);
			for (var i = 0; i < variableCount; i++)	{
				if (!isVariableName(variables[i]) && !isFunctionName(variables[i])) continue;
				connection.m_variables[array_length(connection.m_variables)] = getNode(variables[i]);
			}
		}
		switch (type) {
			case HoneyConnection.SET: {
				addVariableConnections(connection, [ args[0] ]); 
				addVariableConnections(connection, args[1]); 
			} break;
			case HoneyConnection.IF: addVariableConnections(connection, args); break;
			case HoneyConnection.CALL: addVariableConnections(connection, args); break;
			case HoneyConnection.RETURN: addVariableConnections(connection, args); break;
		}
		
		return toNode;
	}
	static addVariable = function(node, variable) {		
		node.m_variables[array_length(node.m_variables)] = getNode(variable);
	}

	static evaluate = function(args) {
		if (!is_array(args)) 
			throw("CANNOT EVALUATE NON-ARRAY \"" + string(args) + "\", THANKS");
		
		function evaluateHelper(args, origin) {
			var result = {
				m_origin: origin,
				m_left: origin, 	
				m_right: origin,
				m_value: 0,
			}
			
			var symbol = args[origin];
			var firstChar = string_char_at(symbol, 1);
			
			if (isVariableName(symbol)) {
				result.m_value = getNode(args[origin]).m_value;
			} else if (isNumber(firstChar)) {
				result.m_value = real(args[origin]);
			} else if (isSymbol(symbol)) {
				result.m_left = origin + 1;
				var leftResult = evaluateHelper(args, result.m_left);
				result.m_right = max(result.m_left + 1, leftResult.m_right + 1);
				var rightResult = evaluateHelper(args, result.m_right);
				
				switch (symbol) {
					default: throw("EVALUATION SYMBOL \"" + symbol + "\" NOT COVERED."); break;
					case "<": result.m_value = leftResult.m_value < rightResult.m_value ? 1 : 0;
					case "+": result.m_value = leftResult.m_value + rightResult.m_value;
					case "-": result.m_value = leftResult.m_value - rightResult.m_value;
					case "*": result.m_value = leftResult.m_value * rightResult.m_value;
					case "/": result.m_value = leftResult.m_value / rightResult.m_value;
				}
			} else if (symbol == "@") {
				result.m_left = origin + 1;
				var functionName = args[result.m_left];
				var functionNode = getNode(functionName);
				var functionArgs = functionNode.m_args;
				if (functionArgs == undefined) 
					throw("COULD NOT FIND FUNCTION ARGS FOR \"" + functionName + "\"");
				
				var argumentCount = array_length(functionArgs) > 0 ? 1 : 0;
				result.m_right += argumentCount * 2;
				if (array_length(functionArgs) > 1) {
					while (args[result.m_right] == ",")  {
						result.m_right++;
						argumentCount++;
					}
				}
				if (argumentCount < array_length(functionArgs))
					throw("MORE ARGUMENTS NEEDED FOR FUNCTION CALL TO \"" + functionName + "\"");
				
				var arguments = [];
				for (var i = 0; i < argumentCount; i++) {
					var rightResult = evaluateHelper(args, result.m_right);
					arguments[i] = rightResult.m_value;
					result.m_right = max(result.m_right + 1, rightResult.m_right + 1);
				}
				
				result.m_value = call(functionName, arguments);
			} else {
				throw("CANNOT EVALUATE SYMBOL \"" + symbol + "\".");
			}
			return result;
		}
		return evaluateHelper(args, 0).m_value;
	}
	static call = function(name, args = []) {
		function callNode(startNode) {
			var currentNode = startNode;
			do {
				var connectionCount = array_length(currentNode.m_connections);
				for (var i = 0; i < connectionCount; i++) {
					var _currentNode = currentNode;
					var connection = currentNode.m_connections[i];
					switch (currentNode.m_connections[i].m_type) {
						case HoneyConnection.SET: 
							getNode(connection.m_args[0]).m_value = evaluate(connection.m_args[1]);
							currentNode = connection.m_to; 
						break;
						case HoneyConnection.IF: 
							var conditionValue = evaluate(connection.m_args);
							if (conditionValue > 0)
								currentNode = connection.m_to; 
						break;
						case HoneyConnection.JUMP: currentNode = connection.m_to; break;
						case HoneyConnection.CALL: {
							// cheeky call.
							var argCopy = [];
							array_copy(argCopy, 0, connection.m_args, 1, array_length(connection.m_args) - 1);
							call(connection.m_args[0], argCopy); 
						} break;
						case HoneyConnection.RETURN: return evaluate(connection.m_args);
					}
					if (_currentNode != currentNode) break;
				}
			} until (currentNode == startNode);
		}
		
		var functionName = getFunctionName(name, "");
		for (var i = 0; i < array_length(m_functions); i++) {
			if (m_functions[i].m_name != functionName) continue;
			return callNode(m_functions[i]);
		}
		return undefined;
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
					
			var dx = cx + (sin(a * i) * size), dy = cy + (-cos(a * i) * size);
			
			draw_circle(dx, dy, 8.0, true);
			draw_text(dx, dy, m_nodes[i].m_name);
			
			var connectionCount = array_length(m_nodes[i].m_connections);
			for (var c = 0; c < connectionCount; c++) {
				var to = m_nodes[i].m_connections[c].m_to;
				var toIndex = getIndex(m_nodes, to);
				
				var tx = cx + (sin(a * toIndex) * size), ty = cy + (-cos(a * toIndex) * size);
				var rx = (tx - dx), ry = (ty - dy);
				
				switch (m_nodes[i].m_connections[c].m_type) {
					default: draw_set_color(c_white); break;
					case HoneyConnection.IF: draw_set_color(c_orange); break;
					case HoneyConnection.JUMP: draw_set_color(c_aqua); break;
					case HoneyConnection.SET: draw_set_color(c_green); break;
				}
				draw_line(dx, dy, tx, ty);
				//draw_circle(tx - rx * 0.1, ty - ry * 0.1, 5.0, false);
			}
			for (var c = 0; c < connectionCount; c++) {
				var to = m_nodes[i].m_connections[c].m_to;
				var toIndex = getIndex(m_nodes, to);
				
				var tx = cx + (sin(a * toIndex) * size), ty = cy + (-cos(a * toIndex) * size);
				var rx = (tx - dx), ry = (ty - dy);
				
				draw_set_color(c_red);
				var variableCount = array_length(m_nodes[i].m_connections[c].m_variables);
				for (var v = 0; v < variableCount; v++) {
					var to = m_nodes[i].m_connections[c].m_variables[v];
					var toIndex = getIndex(m_nodes, to);
				
					var fx = cx + (sin(a * toIndex) * size),
						fy = cy + (-cos(a * toIndex) * size);
					draw_line(fx, fy, dx + (rx * 0.7), dy + (ry * 0.7));
					draw_circle(dx + (rx * 0.7), dy + (ry * 0.7), 3.0, false);
				}
			}
		}
	}
	
	static parseCode = function(code, selfInfo = {}) {
		if (!struct_exists(selfInfo, "m_scope")) 
			selfInfo.m_scope = "";
		if (!struct_exists(selfInfo, "m_topScope")) 
			selfInfo.m_topScope = true;
		if (!struct_exists(selfInfo, "m_root")) 
			selfInfo.m_root = undefined;
		var deriveInfo = {};
		deriveInfo.m_scope = selfInfo.m_scope;
		deriveInfo.m_topScope = false;
		deriveInfo.m_root = selfInfo.m_root;
		
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
					if (type == SymbolType.Variable) {
						currentSymbol = getVariableName(currentSymbol, scope)
					}
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
						sortedSymbols = array_concat([ symbol ], sortedSymbols);
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
				
				return symbols;
			}		
			return getSymbols(value, 0, string_length(value), scope);
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
							case "func":
							case "val":
							case "csv":
							case "condition": {
								var allowedCharacters = "";
								switch (type) {
									case "var": allowedCharacters = "#qwertyuiopasdfghjklzxcvbnm1234567890"; break;
									case "func": allowedCharacters = "qwertyuiopasdfghjklzxcvbnm1234567890"; break;
									case "val": allowedCharacters = " 1234567890.#qwertyuiopasdfghjklzxcvbnm+-/*(),"; break;
									case "csv": allowedCharacters = " qwertyuiopasdfghjklzxcvbnm1234567890,"; break;
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
									case "var": {
										content = getVariableName(content, scope);
										getNode(content);
									} break;
									case "func": {
										content = getFunctionName(content, scope);
									} break;
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
		function mergeNodes(nodes, tracking, info) {
			if (info.m_topScope) return;
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
				data = readFormat(code, "%var% = %val%;*",  selfInfo.m_scope);
				if (data != undefined) {
					var node = appendNode(nodes, addConnection(getLastNode(nodes), undefined, HoneyConnection.SET, [ data[0], data[1] ]));
					mergeNodes(nodes, parseCode(data[2], selfInfo), selfInfo);
					break;
				}
				
				// Unhandled.
				show_debug_message("UNHANDLED KEYWORD " + keyword);
			} break;
			
			case "": break;
							
			case "fn": {
				var data = readFormat(code, "fn %func%(%csv%) %block%*", selfInfo.m_scope);
				if (data == undefined) return;
				
				var functionName = data[0],
					functionArgs = data[1],
					functionCode = data[2];
				
				var functionNode = getNode(functionName, true);
				deriveInfo.m_scope = getScope(deriveInfo.m_scope, functionName);
				
				functionNode.m_args = functionArgs; 
				for (var i = 0; i < array_length(functionNode.m_args); i++) {
					functionNode.m_args[i] = getVariableName(functionNode.m_args [i], deriveInfo.m_scope);
				}
				m_functions[array_length(m_functions)] = functionNode;
				
				appendNode(nodes, functionNode);
				mergeNodes(nodes, parseCode(functionCode, deriveInfo), deriveInfo);
				if (nodes.m_last != functionNode)
					addConnection(nodes.m_last, functionNode, HoneyConnection.JUMP);	
				
				mergeNodes(nodes, parseCode(data[3], selfInfo), selfInfo);
			} break;
			
			case "if": {
				var data = readFormat(code, "if (%condition%) %block%*", selfInfo.m_scope);
				if (data == undefined) return;

				var ifCondition = data[0],
					ifCode = data[1],
					nextCode = data[2];

				var rootNode = getLastNode(nodes);
				var codeNodes = parseCode(ifCode, deriveInfo);				
				addConnection(rootNode, codeNodes.m_first, HoneyConnection.IF, ifCondition);
				appendNode(nodes, codeNodes.m_last);
				
				var jumps = [ rootNode ]; 
				var ends = [ codeNodes.m_last ]; 
				while (string_length(nextCode) > 0) {
					var next = parseCode(nextCode, selfInfo);
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
							var block = parseCode(next.m_ifCode, deriveInfo);
							appendNode(addConnection(rootNode, block.m_first, HoneyConnection.IF, next.m_ifCondition));
							nextCode = next.m_nextCode;
							ends[array_length(ends)] = block.m_last;
						} break;
						case "else": {
							var block = parseCode(next.m_ifCode, deriveInfo);
							appendNode(nodes, addConnection(rootNode, block.m_first, HoneyConnection.JUMP));
							nextCode = next.m_nextCode;
							jumps = [];
							ends[array_length(ends)] = block.m_last;
						} break;
					}
				}
			} break;
			case "elif": {
				var data = readFormat(code, "elif (%condition%) %block%*", selfInfo.m_scope);
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
				var data = readFormat(code, "else %block%*", selfInfo.m_scope);
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
				var data = readFormat(code, "for %var%(%val%; %val%) %block%*", selfInfo.m_scope);
				if (data == undefined) return;

				var forVar = data[0],
					forFrom = data[1],
					forTo = data[2],
					forCode = data[3];
				
				// TODO: Polarity.
				var forNode = appendNode(nodes, addConnection(getLastNode(nodes), undefined, HoneyConnection.SET, [ forVar, forFrom ]));
				appendNode(nodes, addConnection(forNode, undefined, HoneyConnection.IF, array_concat([ "<", forVar ], forTo)));
				mergeNodes(nodes, parseCode(forCode, deriveInfo), deriveInfo);
				appendNode(nodes, addConnection(getLastNode(nodes), undefined, HoneyConnection.SET, [ forVar, [ "+", forVar, "1" ]]));
				addConnection(getLastNode(nodes), forNode, HoneyConnection.JUMP);
				nodes.m_last = forNode;
				mergeNodes(nodes, parseCode(data[4], selfInfo), selfInfo);
			} break;
			
			case "return":{
				var data = readFormat(code, "return %val%;*", selfInfo.m_scope);
				if (data == undefined) return;
				appendNode(nodes, addConnection(getLastNode(nodes), getLastNode(nodes), HoneyConnection.RETURN, data[0]));
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
	parseCode(fileContents);
	
	file_text_close(file);
}