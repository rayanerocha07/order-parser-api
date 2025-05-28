# frozen_string_literal: true

require 'test_helper'

module Api
  class OrdersControllerTest < ActionDispatch::IntegrationTest
    def setup
      @file_path = Rails.root.join('tmp', 'last_upload.txt')
      fixture_path = Rails.root.join('test', 'fixtures', 'files', 'data_1.txt')
      File.write(@file_path, File.read(fixture_path)) unless File.exist?(@file_path)
    end

    def teardown
      FileUtils.rm_f(@file_path)
    end

    def test_should_post_upload
      fixture_path = Rails.root.join('test', 'fixtures', 'files', 'data_1.txt')
      file = fixture_file_upload(fixture_path, 'text/plain')
      post upload_api_orders_url, params: { files: [file] }
      assert_response :success
    end

    def test_should_get_index
      get api_orders_url
      assert_response :success
    end

    def test_should_return_error_when_no_file_uploaded
      FileUtils.rm_f(@file_path)

      get api_orders_url
      assert_response :not_found
    end

    def test_index_filter_by_order_id
      get api_orders_url, params: { order_id: 755 }
      assert_response :success
      data = JSON.parse(response.body)
      assert data.any?, 'Esperava encontrar pelo menos um resultado'

      orders = data.flat_map { |user| user['orders'] }
      assert orders.any? { |order| order['order_id'] == 755 }, 'Esperava encontrar pedido com ID 755'
    end

    def test_index_filter_by_date_range
      get api_orders_url, params: { data_inicio: '2021-03-08', data_fim: '2021-03-08' }
      assert_response :success
      data = JSON.parse(response.body)
      assert_equal 2, data.size
      assert_equal '2021-03-08', data.first['orders'].first['date']
    end
  end
end
