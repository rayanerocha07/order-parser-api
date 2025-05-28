# frozen_string_literal: true

module Api
  class OrdersController < ApplicationController
    FILE_PATH = Rails.root.join('tmp', 'last_upload.txt')

    def upload
      files = Array(params[:files])

      return render json: { error: 'Nenhum arquivo enviado' }, status: :bad_request if files.empty?

      File.open(FILE_PATH, 'w') do |f|
        files.each { |file| f.write(file.read) }
      end

      message = files.size > 1 ? 'Arquivos processados com sucesso' : 'Arquivo processado com sucesso'
      render json: { message: message }, status: :ok
    end

    def index
      return render_no_file_error unless File.exist?(FILE_PATH)

      data = filtered_data
      render json: OrderParser.normalize_by_user(data)
    end

    private

    def render_no_file_error
      render json: { error: 'Nenhum arquivo foi processado ainda' }, status: :not_found
    end

    def filtered_data
      data = OrderParser.parse_file(FILE_PATH)
      data = filter_by_order_id(data)
      filter_by_date_range(data)
    end

    def filter_by_order_id(data)
      return data unless params[:order_id].present?

      data.select { |d| d[:order_id] == params[:order_id].to_i }
    end

    def filter_by_date_range(data)
      return data unless params[:data_inicio].present? || params[:data_fim].present?

      start_date = parse_date_param(params[:data_inicio])
      end_date = parse_date_param(params[:data_fim])

      data.select { |d| date_in_range?(d[:date], start_date, end_date) }
    end

    def parse_date_param(date_param)
      Date.parse(date_param) if date_param.present?
    end

    def date_in_range?(date_str, start_date, end_date)
      date = Date.parse(date_str)
      after_start = start_date ? date >= start_date : true
      before_end = end_date ? date <= end_date : true
      after_start && before_end
    end
  end
end
