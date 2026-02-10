# frozen_string_literal: true

RSpec.describe Trifle::Docs::Helper::Sitemap do
  describe '.xml' do
    let(:updated_at) { Time.utc(2026, 2, 10, 5, 10, 46) }
    let(:sitemap) do
      {
        '_meta' => { 'url' => '/', 'updated_at' => updated_at },
        'trifle-app' => {
          '_meta' => { 'url' => '/trifle-app', 'updated_at' => updated_at },
          'api' => {
            '_meta' => { 'url' => '/trifle-app/api', 'updated_at' => updated_at }
          }
        },
        'blog' => {
          '_meta' => { 'url' => 'https://trifle.io/blog', 'updated_at' => updated_at }
        },
        'asset' => {
          '_meta' => { 'url' => '/logo.svg', 'type' => 'file', 'updated_at' => updated_at }
        }
      }
    end

    before do
      allow(Trifle::Docs).to receive(:sitemap).and_return(sitemap)
    end

    it 'builds absolute loc values from base_url' do
      xml = described_class.xml(base_url: 'https://docs.trifle.io')

      expect(xml).to include('<loc>https://docs.trifle.io/</loc>')
      expect(xml).to include('<loc>https://docs.trifle.io/trifle-app</loc>')
      expect(xml).to include('<loc>https://docs.trifle.io/trifle-app/api</loc>')
    end

    it 'supports base_url path prefixes' do
      xml = described_class.xml(base_url: 'https://docs.trifle.io/reference')

      expect(xml).to include('<loc>https://docs.trifle.io/reference/</loc>')
      expect(xml).to include('<loc>https://docs.trifle.io/reference/trifle-app/api</loc>')
    end

    it 'uses configuration sitemap_base_url when no base_url is passed' do
      config = Trifle::Docs::Configuration.new
      config.sitemap_base_url = 'https://docs.trifle.io'

      xml = described_class.xml(config: config)

      expect(xml).to include('<loc>https://docs.trifle.io/trifle-app</loc>')
    end

    it 'keeps already absolute urls unchanged' do
      xml = described_class.xml(base_url: 'https://docs.trifle.io')

      expect(xml).to include('<loc>https://trifle.io/blog</loc>')
    end

    it 'falls back to relative urls when base_url is invalid' do
      xml = described_class.xml(base_url: 'docs.trifle.io')

      expect(xml).to include('<loc>/trifle-app</loc>')
      expect(xml).to include('<loc>/trifle-app/api</loc>')
    end

    it 'skips file entries' do
      xml = described_class.xml(base_url: 'https://docs.trifle.io')

      expect(xml).not_to include('logo.svg')
    end
  end
end
