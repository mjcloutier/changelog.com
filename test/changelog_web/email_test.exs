defmodule ChangelogWeb.EmailTest do
  use Changelog.SchemaCase
  use Bamboo.Test

  alias Changelog.Newsletters
  alias ChangelogWeb.Email

  setup do
    person = build(:person, auth_token: "54321", auth_token_expires_at: Timex.now())
    {:ok, person: person}
  end

  test "comment mention", %{person: person} do
    item = build(:published_news_item, id: 123)
    comment = build(:news_item_comment, news_item: item, id: 321, content: "@#{person.handle}")
    email = Email.comment_mention(person, comment)
    assert email.to == person
    assert email.html_body =~ ~r/#{person.handle}/i
  end

  test "comment subscription", %{person: person} do
    item = build(:published_news_item, id: 123)
    sub = build(:subscription_on_item, person: person, item: item)
    comment = build(:news_item_comment, news_item: item, id: 321)
    email = Email.comment_subscription(sub, comment)

    assert email.to == person
    assert email.subject =~ ~r/#{item.headline}/i
  end

  test "community welcome", %{person: person} do
    email = Email.community_welcome(person)

    assert email.to == person
    assert email.subject =~ ~r/welcome/i
    assert email.html_body =~ ~r/welcome/i
  end

  test "episode published", %{person: person} do
    # this test needs to insert records for recommendation retrieval
    person = insert(person)
    podcast = insert(:podcast)
    sub = insert(:subscription_on_podcast, id: 1, person: person, podcast: podcast)
    episode = insert(:published_episode, podcast: podcast)
    email = Email.episode_published(sub, episode)

    assert email.to == person
    assert email.subject =~ ~r/#{podcast.name}/i
  end

  test "guest welcome", %{person: person} do
    email = Email.guest_welcome(person)

    assert email.to == person
    assert email.subject =~ ~r/guest/i
    assert email.html_body =~ ~r/guest/i
  end

  test "guest thanks", _ do
    eg = insert(:episode_guest)
    email = Email.guest_thanks(eg)

    assert email.to == eg.person
    assert email.html_body =~ ~r/#{eg.episode.title}/i
  end

  test "sign in", %{person: person} do
    email = Email.sign_in(person)

    assert email.to == person
    assert email.html_body =~ ~r/sign in/i
  end

  test "subscriber welcome to newsletter", %{person: person} do
    email = Email.subscriber_welcome(person, Newsletters.weekly())

    assert email.to == person
    assert email.subject =~ ~r/welcome/i
    assert email.html_body =~ ~r/subscribed/i
    assert email.html_body =~ ~r/Changelog Weekly/
  end

  test "subscriber welcome to podcast", %{person: person} do
    podcast = build(:podcast)
    email = Email.subscriber_welcome(person, podcast)

    assert email.to == person
    assert email.subject =~ ~r/welcome/i
    assert email.html_body =~ ~r/subscribed/i
    assert email.html_body =~ ~r/#{podcast.name}/
  end
end
