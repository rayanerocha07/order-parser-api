# frozen_string_literal: true

class OrderParser
  def self.parse_file(file_path)
    File.readlines(file_path).map(&:chomp).map { |line| parse_line(line) }
  end

  def self.parse_line(line)
    validate_line_length!(line)

    {
      user_id: parse_user_id(line),
      name: parse_name(line),
      order_id: parse_order_id(line),
      product_id: parse_product_id(line),
      value: parse_value(line),
      date: parse_date(line)
    }
  end

  def self.normalize_by_user(items)
    items.group_by { |i| i[:user_id] }.map do |user_id, user_items|
      build_user_hash(user_id, user_items)
    end
  end

  class << self
    private

    def build_user_hash(user_id, user_items)
      {
        user_id: user_id,
        name: user_items.first[:name],
        orders: build_orders(user_items)
      }
    end

    def build_orders(user_items)
      user_items.group_by { |i| i[:order_id] }.map do |order_id, order_items|
        build_order_hash(order_id, order_items)
      end
    end

    def build_order_hash(order_id, order_items)
      {
        order_id: order_id,
        total: format('%.2f', order_items.sum { |i| i[:value] }),
        date: order_items.first[:date],
        products: build_products(order_items)
      }
    end

    def build_products(order_items)
      order_items.map do |item|
        {
          product_id: item[:product_id],
          value: format('%.2f', item[:value])
        }
      end
    end

    def validate_line_length!(line)
      raise "Linha com tamanho inválido: #{line.length}" unless line.length == 95
    end

    def parse_user_id(line)
      line[0..9].to_i
    end

    def parse_name(line)
      line[10..54].strip
    end

    def parse_order_id(line)
      line[55..64].to_i
    end

    def parse_product_id(line)
      line[65..74].to_i
    end

    def parse_value(line)
      line[75..86].strip.to_f
    end

    def parse_date(line)
      Date.strptime(line[87..94], '%Y%m%d').to_s
    end
  end
end
