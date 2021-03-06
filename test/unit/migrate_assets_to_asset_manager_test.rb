require "test_helper"

class MigrateAssetsToAssetManagerTest < ActiveSupport::TestCase
  setup do
    Services.asset_manager.stubs(:whitehall_asset).raises(GdsApi::HTTPNotFound.new(404))

    FileUtils.mkdir_p(organisation_logo_dir)
    FileUtils.cp(dummy_asset_path, organisation_logo_path)

    @subject = MigrateAssetsToAssetManager.new('system/uploads/organisation/logo')
  end

  teardown do
    FileUtils.rm_rf(organisation_logo_dir)
  end

  test 'it calls create_whitehall_asset for each file in the list' do
    Services.asset_manager.expects(:create_whitehall_asset)
      .with(has_entry(:file, responds_with(:read, File.read(organisation_logo_path))))

    @subject.perform
  end

  test 'it calls create_whitehall_asset with the legacy file path' do
    Services.asset_manager.expects(:create_whitehall_asset).with(
      has_entry(:legacy_url_path, '/government/uploads/system/uploads/organisation/logo/1/logo.jpg')
    )

    @subject.perform
  end

  test 'it calls create_whitehall_asset with the legacy last modified time' do
    expected_last_modified = File.stat(organisation_logo_path).mtime

    Services.asset_manager.expects(:create_whitehall_asset).with(
      has_entry(:legacy_last_modified, expected_last_modified)
    )

    @subject.perform
  end

  test 'it calls create_whitehall_asset with the legacy etag' do
    expected_etag = [
      File.stat(organisation_logo_path).mtime.to_i.to_s(16),
      File.stat(organisation_logo_path).size.to_i.to_s(16),
    ].join('-')

    Services.asset_manager.expects(:create_whitehall_asset).with(
      has_entry(:legacy_etag, expected_etag)
    )

    @subject.perform
  end

  test 'it calls create_whitehall_asset with the draft flag set to false by default' do
    Services.asset_manager.expects(:create_whitehall_asset).with(
      has_entry(:draft, false)
    )

    @subject.perform
  end

  test 'it calls create_whitehall_asset with the draft flag set to true if explicitly set' do
    subject = MigrateAssetsToAssetManager.new('system/uploads/organisation/logo', true)

    Services.asset_manager.expects(:create_whitehall_asset).with(
      has_entry(:draft, true)
    )

    subject.perform
  end

  test 'it does not call create_whitehall_asset if the asset already exists in asset manager' do
    Services.asset_manager.stubs(:whitehall_asset).returns('id' => 'http://asset-manager/assets/asset-id')
    Services.asset_manager.expects(:create_whitehall_asset).never

    @subject.perform
  end

  test 'to_s is a count of the number of files to be migrated' do
    assert_equal 'Migrating 1 file', @subject.to_s
  end

private

  def organisation_logo_dir
    File.join(Whitehall.clean_uploads_root, 'system', 'uploads', 'organisation', 'logo', '1')
  end

  def organisation_logo_path
    File.join(organisation_logo_dir, 'logo.jpg')
  end

  def dummy_asset_path
    Rails.root.join('test', 'fixtures', 'images', '960x640_jpeg.jpg')
  end
end

class MigrateAttachmentsToAssetManagerTest < ActiveSupport::TestCase
  setup do
    @attachments_parent_dir = Pathname.new(File.join(Whitehall.clean_uploads_root, 'system', 'uploads', 'attachment_data', 'file'))

    FileUtils.mkdir_p(@attachments_parent_dir.join('100'))
    FileUtils.mkdir_p(@attachments_parent_dir.join('200'))

    @migrator = stub('migrator', perform: nil)
    MigrateAssetsToAssetManager.stubs(:new).returns(@migrator)
  end

  test 'migrates attachment directory 100 and sets attachments as draft' do
    MigrateAssetsToAssetManager.stubs(:new).with('system/uploads/attachment_data/file/100', true).returns(@migrator)
    @migrator.expects(:perform)

    MigrateAssetsToAssetManager.migrate_attachments
  end

  test 'migrates attachment directory 200 and sets attachments as draft' do
    MigrateAssetsToAssetManager.stubs(:new).with('system/uploads/attachment_data/file/200', true).returns(@migrator)
    @migrator.expects(:perform)

    MigrateAssetsToAssetManager.migrate_attachments
  end

  test 'specifying a start and end range' do
    MigrateAssetsToAssetManager.expects(:new).with('system/uploads/attachment_data/file/100', true).never
    MigrateAssetsToAssetManager.expects(:new).with('system/uploads/attachment_data/file/200', true).returns(@migrator)
    @migrator.expects(:perform)

    MigrateAssetsToAssetManager.migrate_attachments(150, 250)
  end

  test '.directory_number_from_attachment_dir' do
    attachment_dir = Pathname.new('system/uploads/attachment_data/file/100')
    assert_equal 100, MigrateAssetsToAssetManager.directory_number_from_attachment_dir(attachment_dir)
  end
end

class AssetFilePathsTest < ActiveSupport::TestCase
  setup do
    FileUtils.mkdir_p(organisation_logo_dir)
    FileUtils.mkdir_p(other_asset_dir)

    FileUtils.cp(dummy_asset_path, organisation_logo_path)
    FileUtils.cp(dummy_asset_path, other_asset_path)

    @subject = MigrateAssetsToAssetManager::AssetFilePaths.new('system/uploads/organisation/logo')
  end

  teardown do
    FileUtils.rm_rf(organisation_logo_dir)
    FileUtils.rm_rf(other_asset_dir)
  end

  test 'delegates each to relative_file_paths' do
    assert @subject.respond_to?(:each)
  end

  test 'delegates size to relative_file_paths' do
    assert @subject.respond_to?(:size)
  end

  test '#files includes only organisation logos' do
    assert_same_elements ['system/uploads/organisation/logo/1/logo.jpg'], @subject.relative_file_paths
  end

  test '#files does not includes directories' do
    @subject.relative_file_paths.each do |relative_file_path|
      absolute_file_path = File.join(Whitehall.clean_uploads_root, relative_file_path)
      refute File.directory?(absolute_file_path)
    end
  end

  test '#files includes all files when initialised with a top level target directory' do
    subject = MigrateAssetsToAssetManager::AssetFilePaths.new('system/uploads')
    assert_same_elements ['system/uploads/organisation/logo/1/logo.jpg', 'system/uploads/other/other_asset.png'], subject.relative_file_paths
  end

  test '#files includes hidden files' do
    hidden_path = File.join(organisation_logo_dir, '.hidden.jpg')
    FileUtils.cp(dummy_asset_path, hidden_path)

    assert_same_elements ['system/uploads/organisation/logo/1/.hidden.jpg', 'system/uploads/organisation/logo/1/logo.jpg'], @subject.relative_file_paths
  end

private

  def organisation_logo_dir
    File.join(Whitehall.clean_uploads_root, 'system', 'uploads', 'organisation', 'logo', '1')
  end

  def other_asset_dir
    File.join(Whitehall.clean_uploads_root, 'system', 'uploads', 'other')
  end

  def organisation_logo_path
    File.join(organisation_logo_dir, 'logo.jpg')
  end

  def other_asset_path
    File.join(other_asset_dir, 'other_asset.png')
  end

  def dummy_asset_path
    Rails.root.join('test', 'fixtures', 'images', '960x640_jpeg.jpg')
  end
end

class AssetFileTest < ActiveSupport::TestCase
  setup do
    @path = Rails.root.join('test/fixtures/logo.png')
    MigrateAssetsToAssetManager::AssetFile.open(@path) do |file|
      @parts = file.legacy_etag.split('-')
    end
  end

  test 'returns string made up of 2 parts separated by a hyphen' do
    assert_equal 2, @parts.length
  end

  test "has 1st part as file mtime (unix time in seconds written in lowercase hex)" do
    last_modified_hex = @parts.first
    last_modified = last_modified_hex.to_i(16)

    assert_equal File.stat(@path).mtime.to_i, last_modified
  end

  test "has 2nd part as file size (number of bytes written in lowercase hex)" do
    size_hex = @parts.last
    size = size_hex.to_i(16)

    assert_equal File.stat(@path).size, size
  end
end
