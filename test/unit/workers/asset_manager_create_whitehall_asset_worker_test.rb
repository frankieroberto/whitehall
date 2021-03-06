require 'test_helper'

class AssetManagerCreateWhitehallAssetWorkerTest < ActiveSupport::TestCase
  setup do
    @file = Tempfile.new('asset', Dir.mktmpdir)
    @legacy_url_path = 'legacy-url-path'
    @worker = AssetManagerCreateWhitehallAssetWorker.new
  end

  test 'creates a whitehall asset using a file object at the correct path' do
    Services.asset_manager.expects(:create_whitehall_asset).with do |args|
      args[:file].path == @file.path
    end

    @worker.perform(@file.path, @legacy_url_path)
  end

  test 'creates a whitehall asset using the legacy_url_path passed to the worker' do
    Services.asset_manager.expects(:create_whitehall_asset).with(has_entry(legacy_url_path: @legacy_url_path))

    @worker.perform(@file.path, @legacy_url_path)
  end

  test 'does not mark the asset as draft by default' do
    Services.asset_manager.expects(:create_whitehall_asset).with(Not(has_key(:draft)))

    @worker.perform(@file.path, @legacy_url_path)
  end

  test 'marks the asset as draft if instructed' do
    Services.asset_manager.expects(:create_whitehall_asset).with(has_entry(draft: true))

    @worker.perform(@file.path, @legacy_url_path, true)
  end

  test 'removes the file after it has been successfully uploaded' do
    @worker.perform(@file.path, @legacy_url_path)
    refute File.exist?(@file.path)
  end

  test 'removes the directory after it has been successfully uploaded' do
    @worker.perform(@file.path, @legacy_url_path)
    refute Dir.exist?(File.dirname(@file))
  end
end
