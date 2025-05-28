# frozen_string_literal: true

class OrderParserTest < ActiveSupport::TestCase
  def setup
    # Lê o arquivo inteiro e pega a primeira linha
    file_path = Rails.root.join('test', 'fixtures', 'files', 'data_1.txt')
    @line = File.readlines(file_path).first.chomp
  end

  def test_parse_line_extracts_fields_correctly
    result = OrderParser.parse_line(@line)

    assert_equal 70, result[:user_id]
    assert_equal 'Palmer Prosacco', result[:name]
    assert_equal 753, result[:order_id]
    assert_equal 3, result[:product_id]
    assert_in_delta 1836.74, result[:value], 0.01
    assert_equal '2021-03-08', result[:date]
  end

  def test_parse_line_raises_error_for_invalid_line
    invalid_line = 'linha muito curta'

    error = assert_raises(RuntimeError) do
      OrderParser.parse_line(invalid_line)
    end

    assert_match(/Linha com tamanho inválido/, error.message)
  end

  def test_normalize_by_user_groups_orders_by_user
    file_path = Rails.root.join('test', 'fixtures', 'files', 'data_1.txt')
    parsed = OrderParser.parse_file(file_path)
    result = OrderParser.normalize_by_user(parsed)

    assert result.any?, 'Nenhum usuário encontrado'
    result.each { |user| validate_user(user) }
  end

  def test_normalize_by_user_validates_structure_and_values
    file_path = Rails.root.join('test', 'fixtures', 'files', 'data_1.txt')
    parsed = OrderParser.parse_file(file_path)
    result = OrderParser.normalize_by_user(parsed)

    assert_equal 100, result.size

    user = result.first
    validate_user_summary(user)

    order = user[:orders].find { |o| o[:order_id] == 753 }
    validate_order_summary(order)
  end
end

private

def validate_user(user)
  assert user[:user_id], 'Usuário sem :user_id'
  assert user[:name], 'Usuário sem :name'
  assert user[:orders].is_a?(Array), 'Usuário sem lista de pedidos'
  assert user[:orders].any?, 'Usuário sem pedidos'

  user[:orders].each { |order| validate_order(order) }
end

def validate_order(order)
  assert order[:order_id], 'Pedido sem :order_id'
  assert order[:date], 'Pedido sem :date'
  assert order[:total], 'Pedido sem :total'
  assert order[:products].is_a?(Array), 'Pedido sem lista de produtos'
  assert order[:products].any?, 'Pedido sem produtos'

  order[:products].each { |product| validate_product(product) }
end

def validate_product(product)
  assert product[:product_id], 'Produto sem :product_id'
  assert product[:value], 'Produto sem :value'
end

def validate_user_summary(user)
  assert_equal 70, user[:user_id]
  assert_equal 'Palmer Prosacco', user[:name]
  assert_equal 10, user[:orders].size
end

def validate_order_summary(order)
  assert_equal '2021-03-08', order[:date]
  assert_equal '4252.53', order[:total]
  assert_equal 4, order[:products].size
  validate_products(order[:products])
end

def validate_products(products)
  expected_products = [
    { product_id: 3, value: '1836.74' },
    { product_id: 3, value: '1009.54' },
    { product_id: 4, value: '618.79' },
    { product_id: 3, value: '787.46' }
  ]

  assert_equal expected_products, products
end
