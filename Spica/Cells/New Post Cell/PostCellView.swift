//
//  PostCellView.swift
//  Spica
//
//  Created by Adrian Baumgart on 05.07.20.
//

import KMPlaceholderTextView
import SwiftKeychainWrapper
import UIKit

// https://github.com/devxoul/UITextView-Placeholder

protocol PostCellViewDelegate {
    func selectedUser(username: String, indexPath: IndexPath)
    func selectedURL(url: String, indexPath: IndexPath)
    func selectedPost(post: String, indexPath: IndexPath)

    func copyPostID(id: String)
    func deletePost(id: String)

    func replyToPost(id: String)

    func repost(id: String, username: String)
}

class PostCellView: UITableViewCell, UITextViewDelegate {
    var delegate: PostCellViewDelegate!
    var indexPath: IndexPath!

    var post: Post? {
        didSet {
            // ASSIGN VALUES
            pfpImageView.image = post?.author.image
            contentTextView.isUserInteractionEnabled = true
            contentTextView.delaysContentTouches = false
            // required for tap to pass through on to superview & for links to work
            contentTextView.isScrollEnabled = false
            contentTextView.isEditable = false
            contentTextView.isUserInteractionEnabled = true
            contentTextView.isSelectable = true

            if post?.author.isPlus == true {
                let font: UIFont? = UIFont.boldSystemFont(ofSize: 18)

                let fontSuper: UIFont? = UIFont.boldSystemFont(ofSize: 12)
                let attrDisplayName = NSMutableAttributedString(string: "\(post!.author.displayName)+", attributes: [.font: font!])
                attrDisplayName.setAttributes([.font: fontSuper!, .baselineOffset: 10], range: NSRange(location: (post?.author.displayName.count)!, length: 1))

                displaynameLabel.attributedText = attrDisplayName
            } else {
                displaynameLabel.text = post!.author.displayName
            }

            usernameLabel.text = "@\(post!.author.username)"
            voteCountLabel.text = String(post!.score)
            contentTextView.delegate = self

            let attributedText = NSMutableAttributedString(string: "")

            let normalFont: UIFont? = UIFont.systemFont(ofSize: 15)

            let postContent = post?.content.replacingOccurrences(of: "\n", with: " \n ")

            let splitContent = postContent!.split(separator: " ")
            for word in splitContent {
                if word.hasPrefix("@"), word.count > 1 {
                    let selectablePart = NSMutableAttributedString(string: String(word) + " ")

                    let username = removeSpecialCharsFromString(text: String(word))
                    selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: username.count))

                    selectablePart.addAttribute(.link, value: "user:\(username)", range: NSRange(location: 0, length: username.count))
                    attributedText.append(selectablePart)
                } else if word.hasPrefix("%"), word.count > 1 {
                    let selectablePart = NSMutableAttributedString(string: String(word) + " ")

                    selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))

                    let postID = word[word.index(word.startIndex, offsetBy: 1) ..< word.endIndex]
                    selectablePart.addAttribute(.link, value: "post:\(postID)", range: NSRange(location: 0, length: selectablePart.length - 1))

                    attributedText.append(selectablePart)
                } else if String(word).isValidURL, word.count > 1 {
                    let selectablePart = NSMutableAttributedString(string: String(word) + " ")
                    selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))

                    selectablePart.addAttribute(.link, value: "url:\(word)", range: NSRange(location: 0, length: selectablePart.length - 1))
                    attributedText.append(selectablePart)
                } else if word.hasPrefix("#"), word.count > 1 {
                    let selectablePart = NSMutableAttributedString(string: String(word) + " ")

                    selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))

                    let tag = word[word.index(word.startIndex, offsetBy: 1) ..< word.endIndex]
                    selectablePart.addAttribute(.link, value: "tag:\(tag)", range: NSRange(location: 0, length: selectablePart.length - 1))
                    attributedText.append(selectablePart)
                } else {
                    if word == "\n" {
                        attributedText.append(NSAttributedString(string: "\n"))
                    } else {
                        attributedText.append(NSAttributedString(string: word + " "))
                    }
                }
            }

            attributedText.addAttributes([.font: normalFont!, .foregroundColor: UIColor.label], range: NSRange(location: 0, length: attributedText.length))
            contentTextView.attributedText = attributedText

            dateLabel.text = globalDateFormatter.string(from: post!.date)
            replyCountLabel.text = countString(number: post!.repliesCount, singleText: SLocale(.REPLY_SINGULAR), multiText: SLocale(.REPLY_PLURAL))
            if post?.image != nil {
                mediaImageView.image = post?.image!
                mediaImageView.snp.remakeConstraints { make in
                    make.bottom.equalTo(replyCountLabel.snp.top).offset(-16)
                    make.height.equalTo((post?.image?.size.height)! / 3)
                    make.trailing.equalTo(self.snp.trailing).offset(-16)
                    make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
                }
            }

            if post!.voteStatus == 1 {
                upvoteButton.setTitleColor(.systemGreen, for: .normal)
                downvoteButton.setTitleColor(.gray, for: .normal)
            } else if post!.voteStatus == -1 {
                downvoteButton.setTitleColor(.systemRed, for: .normal)
                upvoteButton.setTitleColor(.gray, for: .normal)
            } else {
                upvoteButton.setTitleColor(.systemBlue, for: .normal)
                downvoteButton.setTitleColor(.systemBlue, for: .normal)
            }

            let contextInteraction = UIContextMenuInteraction(delegate: self)
            contentView.addInteraction(contextInteraction)
            moreImageView.isUserInteractionEnabled = true
        }
    }

    var pfpImageView: UIImageView = {
        let imgView = UIImageView(frame: .zero)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        if #available(iOS 13.4, *) {
            imgView.addInteraction(UIPointerInteraction())
        }
        imgView.layer.cornerRadius = 20

        return imgView
    }()

    private var displaynameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .boldSystemFont(ofSize: 17.0)
        label.textAlignment = .left
        label.textColor = .label
        label.text = "Display Name"
        return label
    }()

    private var usernameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 17.0)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.text = "username"
        return label
    }()

    private var moreImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "ellipsis.circle"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        return imageView
    }()

    private var voteCountLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    var upvoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 23)
        button.setTitleColor(.systemBlue, for: .normal)
        if #available(iOS 13.4, *) {
            button.isPointerInteractionEnabled = true
        }
        return button
    }()

    var downvoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("-", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 29)
        button.setTitleColor(.systemBlue, for: .normal)
        if #available(iOS 13.4, *) {
            button.isPointerInteractionEnabled = true
        }
        return button
    }()

    private var mediaImageView: UIImageView = {
        let imgView = UIImageView(frame: .zero)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()

    var contentTextView: KMPlaceholderTextView = {
        let textView = KMPlaceholderTextView(frame: .zero)
        textView.textAlignment = .left
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = .label
        textView.text = "Content"
        textView.dataDetectorTypes = [.link, .lookupSuggestion, .phoneNumber]
        textView.isOpaque = true
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        return textView
    }()

    private var dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Date"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .left
        return label
    }()

    private var replyCountLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Replies"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .right
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // ADD SUBVIEWS
        selectionStyle = .none
        contentView.addSubview(pfpImageView)
        contentView.addSubview(displaynameLabel)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(upvoteButton)
        contentView.addSubview(downvoteButton)
        contentView.addSubview(voteCountLabel)
        contentView.addSubview(contentTextView)
        contentView.addSubview(replyCountLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(mediaImageView)

        contentView.isUserInteractionEnabled = true

        isUserInteractionEnabled = true

        contentTextView.translatesAutoresizingMaskIntoConstraints = false

        voteCountLabel.snp.makeConstraints { make in
            make.centerY.equalTo(contentView.snp.centerY)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.width.equalTo(30)
        }

        upvoteButton.snp.makeConstraints { make in
            make.bottom.equalTo(voteCountLabel.snp.top)
            make.centerX.equalTo(voteCountLabel.snp.centerX)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.width.equalTo(30)
        }

        downvoteButton.snp.makeConstraints { make in
            make.top.equalTo(voteCountLabel.snp.bottom).offset(-8)
            make.centerX.equalTo(voteCountLabel.snp.centerX)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.width.equalTo(30)
        }

        pfpImageView.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.leading.equalTo(upvoteButton.snp.trailing).offset(16)
            make.top.equalTo(contentView.snp.top).offset(16)
        }

        displaynameLabel.snp.makeConstraints { make in
            make.leading.equalTo(pfpImageView.snp.trailing).offset(16)
            make.top.equalTo(contentView.snp.top).offset(16)
            make.height.equalTo(25)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }

        usernameLabel.snp.makeConstraints { make in
            make.leading.equalTo(pfpImageView.snp.trailing).offset(16)
            make.top.equalTo(displaynameLabel.snp.bottom) // .offset(0)
            make.height.equalTo(25)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }

        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.width.equalTo(contentView.frame.width / 2)
        }

        replyCountLabel.snp.makeConstraints { make in
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.width.equalTo(contentView.frame.width / 2)
            make.height.equalTo(30)
            make.top.equalTo(mediaImageView.snp.bottom)
        }

        mediaImageView.snp.makeConstraints { make in
            make.bottom.equalTo(replyCountLabel.snp.top).offset(-16)
            make.height.equalTo(32)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
        }

        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(usernameLabel.snp.bottom).offset(16)
            make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.bottom.equalTo(mediaImageView.snp.top).offset(-16)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentTextView.isEditable = true
        contentTextView.isSelectable = true
        contentTextView.isMultipleTouchEnabled = true
    }

    func textView(_: UITextView, shouldInteractWith URL: URL, in _: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            let stringURL = URL.absoluteString

            if stringURL.hasPrefix("user:@") {
                let username = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 6) ..< stringURL.endIndex]
                delegate.selectedUser(username: String(username), indexPath: indexPath)
            } else if stringURL.hasPrefix("url:") {
                var selURL = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 4) ..< stringURL.endIndex]
                if !selURL.starts(with: "https://"), !selURL.starts(with: "http://") {
                    selURL = "https://" + selURL
                }
                delegate.selectedURL(url: String(selURL), indexPath: indexPath)
            } else if stringURL.isValidURL {
                delegate.selectedURL(url: stringURL, indexPath: indexPath)
            } else if stringURL.hasPrefix("post:") {
                let postID = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 5) ..< stringURL.endIndex]
                delegate.selectedPost(post: String(postID), indexPath: indexPath)
            }
        }
        return false
    }
}

extension PostCellView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in

            self.makeContextMenu()
        })
    }

    func makeContextMenu() -> UIMenu {
        // Create a UIAction for sharing

        var actionsArray = [UIAction]()

        let copyID = UIAction(title: "Copy ID", image: UIImage(systemName: "doc.on.doc")) { _ in
            self.delegate.copyPostID(id: self.post!.id)
        }

        actionsArray.append(copyID)

        let reply = UIAction(title: "Reply", image: UIImage(systemName: "arrowshape.turn.up.left")) { _ in
            self.delegate.replyToPost(id: self.post!.id)
        }

        actionsArray.append(reply)

        let repost = UIAction(title: "Repost", image: UIImage(systemName: "square.and.arrow.up")) { _ in
            self.delegate.repost(id: self.post!.id, username: self.post!.author.username)
        }

        actionsArray.append(repost)

        let userID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")

        if post?.author.id == userID {
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.delegate.deletePost(id: self.post!.id)
            }
            actionsArray.append(delete)
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Post", children: actionsArray)
    }
}
