# frozen_string_literal: true
# == Schema Information
#
# Table name: forum_posts
#
#  id                   :integer          not null, primary key
#  user_id              :integer          not null
#  forum_category_id    :integer          not null
#  title                :string           not null
#  body                 :text             default(""), not null
#  forum_comments_count :integer          default(0), not null
#  edited_at            :datetime
#  last_commented_at    :datetime         not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  locale               :string           default("other"), not null
#
# Indexes
#
#  index_forum_posts_on_forum_category_id  (forum_category_id)
#  index_forum_posts_on_locale             (locale)
#  index_forum_posts_on_user_id            (user_id)
#

class ForumPost < ApplicationRecord
  include LocaleDetectable

  belongs_to :user
  belongs_to :forum_category
  has_many :forum_comments, dependent: :destroy
  has_many :forum_post_participants, dependent: :destroy

  validates :body, presence: true, length: { maximum: 5000 }
  validates :forum_category, presence: true
  validates :last_commented_at, presence: true
  validates :title, presence: true, length: { maximum: 100 }
  validates :user, presence: true

  def notify_discord
    return unless Rails.env.production?

    options = {
      url: ENV.fetch("ANNICT_DISCORD_WEBHOOK_URL_FOR_FORUM_#{forum_category.slug.upcase}")
    }
    host = ENV.fetch("ANNICT_JP_URL")
    url = Rails.application.routes.url_helpers.forum_post_url(self, host: host)
    message = [
      user.profile.name,
      "created the post",
      title,
      url
    ].select(&:present?).join(" ")

    Discord::Notifier.message(message, options)
  end
end
