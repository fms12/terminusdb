:- module(util, [
              % syntax.pl
              % hmm is this right?
              op(601, xfx, @),
              op(601, xfx, ^^),

              % file_utils.pl
              terminus_path/1,
              storage_version_path/2,
              touch/1,
              ensure_directory/1,
              sanitise_file_name/2,
              subdirectories/2,
              files/2,
              directories/2,
              terminus_schema_path/1,
              file_to_predicate/2,

              % types.pl
              is_literal/1,
              is_uri/1,
              is_id/1,
              is_bnode/1,
              is_prefixed_uri/1,
              is_uri_or_id/1,
              is_object/1,
              is_object_or_id/1,
              is_graph_identifier/1,
              is_prefix_db/1,
              is_database_identifier/1,
              is_empty_graph_name/1,
              is_database/1,
              is_read_obj/1,
              is_write_obj/1,
              is_date_time/1,
              is_date/1,
              is_point/1,
              is_coordinate_polygon/1,
              is_date_range/1,
              is_integer_range/1,
              is_decimal_range/1,
              is_gyear/1,
              is_gmonth/1,
              is_gday/1,
              is_gyear_month/1,
              is_gmonth_day/1,
              is_gyear_range/1,
              is_time/1,
              is_boolean/1,
              is_duration/1,
              is_byte/1,
              is_short/1,
              is_int/1,
              is_long/1,
              is_unsigned_byte/1,
              is_unsigned_short/1,
              is_unsigned_int/1,
              is_unsigned_long/1,
              is_positive_integer/1,
              is_negative_integer/1,
              is_nonpositive_integer/1,
              is_nonnegative_integer/1,

              % remote_file.pl
              copy_remote/3,

              % utils.pl
              down_from/3,
              escape_pcre/2,
              get_key/4,
              get_key/3,
              getenv_number/2,
              getenv_default/3,
              getenv_default_number/3,
              get_dict_default/4,
              zip/3,
              intersperse/3,
              interpolate/2,
              interpolate_string/2,
              unique_solutions/3,
              repeat_term/3,
              zero_pad/3,
              pad/4,
              coerce_number/2,
              exhaust/1,
              take/3,
              from_to/4,
              drop/3,
              truncate_list/4,
              sfoldr/4,
              foldm/6,
              mapm/4,
              mapm/5,
              mapm/6,
              exists/2,
              find/3,
              trim/2,
              split_atom/3,
              pattern_string_split/3,
              merge_separator_split/3,
              count/3,
              merge_dictionaries/3,
              command/1,
              coerce_literal_string/2,
              coerce_atom/2,
              coerce_string/2,
              xfy_list/3,
              yfx_list/3,
              snoc/3,
              join/3,
              op(920,fy, *),
              '*'/1,
              op(700,xfy,<>),
              '<>'/2,
              do_or_die/2,
              option_or_die/2,
              die_if/2,
              whole_arg/2,
              random_string/1,
              uri_has_prefix/1,
              uri_has_protocol/1,
              choice_points/1,
              sol_bag/2,
              sol_set/2,
              optional/1,
              member_last/3,
              convlist/4,
              time_to_internal_time/2,
              datetime_to_internal_datetime/2,
              json_read_term/2,
              json_read_term_stream/2,
              json_read_list_stream/2,
              json_read_list_stream_head/3,
              json_init_tail_stream/2,
              json_read_tail_stream/2,
              skip_generate_nsols/3,
              input_to_integer/2,
              duplicates/2,
              has_duplicates/2,
              index_list/2,
              nb_thread_var_init/2,
              nb_thread_var/2,
              uri_encoded_string/3,
              text/1,
              with_memory_file/1,
              with_memory_file_stream/3,
              with_memory_file_stream/4,
              terminal_slash/2,
              dict_field_verifier/3,

              % speculative_parse.pl
              %guess_date/2,
              %guess_datetime_stamp/2,
              %guess_number/2,
              %guess_integer/2,
              %guess_integer_range/2,
              %guess_decimal_range/2,

              % xsd_parser.pl
              digit//1,
              oneDigitNatural//1,
              twoDigitNatural//1,
              threeDigitNatural//1,
              decimal//1,
              digits//1,
              integer//1,
              double//3,
              positiveInteger//1,
              negativeInteger//1,
              nonPositiveInteger//1,
              nonNegativeInteger//1,
              unsignedDecimal//1,
              year//1,
              date//4,
              dateTime//8,
              dateTimeStamp//8,
              gYear//2,
              gYearMonth//3,
              gMonth//2,
              gMonthDay//3,
              gDay//2,
              duration//7,
              yearMonthDuration//3,
              dayTimeDuration//5,
              string/3,
              base64Binary//0,
              hexBinary//0,
              language//0,
              whitespace//0,
              anyBut//1,
              time//5,
              coordinatePolygon//1,
              dateRange//2,
              decimalRange//2,
              email//0,
              gYearRange//2,
              integerRange//2,
              point//2,
              url//0,
              ncname//0,
              nmtoken//0,
              normalizedString//0,

              % benchmark.pl
              benchmark_start/1,
              benchmark_stop/0,
              benchmark_subject_start/1,
              benchmark_subject_stop/1,
              benchmark/1,
              benchmark/0,

              % http_utils.pl
              basic_authorization/3,
              bearer_authorization/2,
              token_authorization/2,

              % json_log.pl
              json_log_error/1,
              json_log_error/3,
              json_log_error_formatted/2,
              json_log_warning/1,
              json_log_warning/3,
              json_log_warning_formatted/2,
              json_log_notice/1,
              json_log_notice/3,
              json_log_notice_formatted/2,
              json_log_info/1,
              json_log_info/3,
              json_log_info_formatted/2,
              json_log_debug/1,
              json_log_debug/3,
              json_log_debug_formatted/2,
              error_log_enabled/0,
              warning_log_enabled/0,
              notice_log_enabled/0,
              info_log_enabled/0,
              debug_log_enabled/0,
              generate_request_id/2,
              saved_request/5,

              % param.pl
              param_check_json/4,
              param_check_search/4,
              param_value_search_required/4,
              param_value_search_optional/5,
              param_value_json_required/4,
              param_value_json_optional/5,
              param_value_search_or_json_required/5,
              param_value_search_or_json_optional/6,
              param_value_search_author/2,
              param_value_search_message/2,
              param_value_search_graph_type/2,

              % data_version.pl
              compare_data_versions/2,
              read_data_version_header/2,
              read_data_version/2,
              write_data_version_header/1,
              transaction_data_version/2,
              validation_data_version/3,
              meta_data_version/3,

              % json_stream.pl
              json_stream_start/1,
              json_stream_end/3,
              json_stream_write_dict/5
          ]).

% note: test_utils is intentionally omitted
:- use_module(util/syntax).
:- use_module(util/file_utils).
:- use_module(util/types).
:- use_module(util/remote_file).
:- use_module(util/utils).
%:- use_module(util/speculative_parse).
:- use_module(util/xsd_parser).
:- use_module(util/benchmark).
:- use_module(util/http_utils).
:- use_module(util/param).
:- use_module(util/json_log).
:- use_module(util/data_version).
:- use_module(util/json_stream).
