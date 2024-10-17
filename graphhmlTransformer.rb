require 'nokogiri'
require 'json'
require 'builder'



#  XML a GraphML -------------------------------------------------------
# Params:
# - xml_file: Ruta del archivo XML de entrada
# - output_file: Ruta del archivo GraphML de salida
def xml_to_graphml(xml_file, output_file)
  # Abre y parsea el archivo XML
  xml_doc = Nokogiri::XML(File.open(xml_file))

  # Abre (o crea) el archivo de salida para escritura
  File.open(output_file, 'w') do |file|
    # Crea un nuevo constructor de XML con salida al archivo
    builder = Builder::XmlMarkup.new(:target => file, :indent => 2)

    # Escribe la cabecera y el esquema GraphML
    builder.instruct!(:xml, :version => "1.0", :encoding => "UTF-8")
    builder.graphml(xmlns: "http://graphml.graphdrawing.org/xmlns",
                    'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                    'xsi:schemaLocation' => "http://graphml.graphdrawing.org/xmlns/1.1/graphml.xsd") do |graphml|
      graphml.graph(id: "G", edgedefault: "directed") do |graph|
        # Itera sobre cada nodo del XML y añade nodos y aristas al GraphML
        xml_doc.root.xpath('//*').each do |node|
          node_id = node.path.gsub('/', '_')
          node_label = node.name
          graph.node(id: node_id, label: node_label)
          node.children.each do |child|
            next if child.text?
            child_id = child.path.gsub('/', '_')
            graph.edge(source: node_id, target: child_id)
          end
        end
      end
    end
  end
  puts "Archivo GraphML guardado en #{output_file}"
end

# JSON a GraphML ----------------------------------------------------------------------
# Params:
# - json_file: Ruta del archivo JSON de entrada
# - output_file: Ruta del archivo GraphML de salida
def json_to_graphml(json_file, output_file)
  # Lee y parsea el archivo JSON
  json_doc = JSON.parse(File.read(json_file))

  # Abre (o crea) el archivo de salida para escritura
  File.open(output_file, 'w') do |file|
    # Crea un nuevo constructor de XML con salida al archivo
    builder = Builder::XmlMarkup.new(:target => file, :indent => 2)

    # Escribe la cabecera y el esquema GraphML
    builder.instruct!(:xml, :version => "1.0", :encoding => "UTF-8")
    builder.graphml(xmlns: "http://graphml.graphdrawing.org/xmlns",
                    'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                    'xsi:schemaLocation' => "http://graphml.graphdrawing.org/xmlns/1.1/graphml.xsd") do |graphml|
      graphml.graph(id: "G", edgedefault: "directed") do |graph|
        # Llama a la función auxiliar para procesar el JSON
        parse_json_node(graph, json_doc, 'root', 'root')
      end
    end
  end
  puts "Archivo GraphML guardado en #{output_file}"
end

# Función auxiliar para parsear nodos JSON y añadirlos al GraphML
# Params:
# - graph: Constructor GraphML
# - node: Nodo actual del JSON
# - path: Ruta actual en el árbol JSON
# - label: Etiqueta para el nodo actual
def parse_json_node(graph, node, path, label)
  # Añade un nodo al GraphML con su correspondiente etiqueta
  graph.node(id: path, label: label)
  if node.is_a?(Hash)
    node.each do |key, value|
      new_path = "#{path}_#{key}"
      # Añade arista entre el nodo padre y el hijo
      graph.edge(source: path, target: new_path)
      # Recursivamente procesa el nodo hijo
      parse_json_node(graph, value, new_path, key)
    end
  elsif node.is_a?(Array)
    node.each_with_index do |value, index|
      new_path = "#{path}_#{index}"
      # Añade arista entre el nodo padre y el hijo
      graph.edge(source: path, target: new_path)
      # Recursivamente procesa el nodo hijo
      parse_json_node(graph, value, new_path, index.to_s)
    end
  else
    # Manejo de los valores finales en el JSON
    value_label = node.to_s
    graph.node(id: "#{path}_value", label: value_label)
    graph.edge(source: path, target: "#{path}_value")
  end
end

# Selecciona el tipo de archivo y realiza la conversión apropiada
# Params:
# - file_path: Ruta del archivo de entrada (XML o JSON)
# - output_file: Ruta del archivo GraphML de salida
def convert_to_graphml(file_path, output_file)
  file_ext = File.extname(file_path).downcase

  case file_ext
  when '.xml'
    xml_to_graphml(file_path, output_file)
  when '.json'
    json_to_graphml(file_path, output_file)
  else
    puts "Tipo de archivo no soportado"
  end
end

# Ejemplo de uso
file_path = 'note.xml' # o 'tu_fichero.json'
output_file = 'salida.graphml'
convert_to_graphml(file_path, output_file)