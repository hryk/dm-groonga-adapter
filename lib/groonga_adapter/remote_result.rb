module DataMapper
  module Adapters
    module GroongaResult
      class Base
        attr_accessor :err_code
        attr_accessor :err_msg
        attr_accessor :start_time
        attr_accessor :elapsed_time

        def initialize(raw_result)
          @err_code, @start_time, @elased_time, @err_msg = raw_result[0]
        end

        def success?
          if @err_code == 0
            true
          else
            false
          end
        end
      end # class Result::Base

      class Count < Base
        attr_accessor :count
        def initialize(raw_result)
          super raw_result
          # [[0,1270199923.22467,5.2e-05],1]
          @count = raw_result[1]
        end
      end

      class Status < Base
        attr_accessor :alloc_count
        attr_accessor :process_starttime
        attr_accessor :uptime
        attr_accessor :version

        def initialize(raw_result)
          super(raw_result)
          if success?
            @alloc_count = raw_result[1]['alloc_count']
            @process_starttime = raw_result[1]['starttime']
            @uptime  = raw_result[1]['uptime']
            @version = raw_result[1]['version']
          end
        end
      end

      class List < Base
        include Enumerable
        attr_accessor :columns
        attr_accessor :rows
#        attr_accessor :raw_rows
#        attr_accessor :raw_columns
        attr_accessor :size

        def initialize(raw_result)
          super(raw_result)
          if success?
            @raw_columns, @rows, @size = if raw_result[1].size > 1
                                               # no count
                                               raws = raw_result[1].dup
                                               [raws.shift,raws,nil]
                                             else
                                               # with count
                                               raws = raw_result[1].dup.shift
                                               size = raws.shift.shift
                                               rawcols = raws.shift
                                               [rawcols, raws, size]
                                             end
            # columns
            @columns = @raw_columns.map {|item| item[0] }
            parse_rows
            self
          end
        end

        def each
          @mash_rows.each do |m|
            yield m
          end
        end

        def to_a
          return @mash_rows unless @mash_rows.nil?
          []
        end

        def parse_rows
          @mash_rows = @rows.map {|row|
            m = Mash.new
            @columns.each_with_index {|item, idx|
              m[@columns[idx]] = row[idx]
            }
            m
          }
        end
      end
    end # now # module Result
  end 
end
