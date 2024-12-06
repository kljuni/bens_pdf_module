require "test_helper"

class Api::V1::FilesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get api_v1_files_create_url
    assert_response :success
  end

  test "should get index" do
    get api_v1_files_index_url
    assert_response :success
  end

  test "should get destroy" do
    get api_v1_files_destroy_url
    assert_response :success
  end

  test "should get import" do
    get api_v1_files_import_url
    assert_response :success
  end
end
