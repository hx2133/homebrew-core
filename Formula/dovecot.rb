class Dovecot < Formula
  desc "IMAP/POP3 server"
  homepage "https://dovecot.org/"
  url "https://dovecot.org/releases/2.2/dovecot-2.2.32.tar.gz"
  mirror "https://fossies.org/linux/misc/dovecot-2.2.32.tar.gz"
  sha256 "160b2151e2af359877f69cb2dcdfe1a3f4138ad3766e3b8562b96616e2f6bc2e"

  bottle do
    sha256 "fee76f57275dfcb96dfe0bba1d1da66bed84301e20da30fdcd9d926f75f0a7a8" => :sierra
    sha256 "7e04c4a47c91a0d92f0b78f2e8152e9f7d3baeddce2dcdcf736289def0f36955" => :el_capitan
    sha256 "c27efcd2976e85ae7160250cd3ee5735fc94653edd6bcd6a0a666e5a2a87e264" => :yosemite
  end

  option "with-pam", "Build with PAM support"
  option "with-pigeonhole", "Add Sieve addon for Dovecot mailserver"
  option "with-pigeonhole-unfinished-features", "Build unfinished new Sieve addon features/extensions"
  option "with-stemmer", "Build with libstemmer support"

  depends_on "openssl"
  depends_on "clucene" => :optional

  resource "pigeonhole" do
    url "https://pigeonhole.dovecot.org/releases/2.2/dovecot-2.2-pigeonhole-0.4.19.tar.gz"
    sha256 "629204bfbdcd3480e1ebcdc246da438323c3ea5fea57480ab859e8b201ad8793"
  end

  resource "stemmer" do
    url "https://github.com/snowballstem/snowball.git",
        :revision => "5137019d68befd633ce8b1cd48065f41e77ed43e"
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --disable-dependency-tracking
      --libexecdir=#{libexec}
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --with-ssl=openssl
      --with-sqlite
      --with-zlib
      --with-bzlib
    ]

    args << "--with-lucene" if build.with? "clucene"
    args << "--with-pam" if build.with? "pam"

    if build.with? "stemmer"
      args << "--with-libstemmer"

      resource("stemmer").stage do
        system "make", "dist_libstemmer_c"
        system "tar", "xzf", "dist/libstemmer_c.tgz", "-C", buildpath
      end
    end

    system "./configure", *args
    system "make", "install"

    if build.with? "pigeonhole"
      resource("pigeonhole").stage do
        args = %W[
          --disable-dependency-tracking
          --with-dovecot=#{lib}/dovecot
          --prefix=#{prefix}
        ]

        args << "--with-unfinished-features" if build.with? "pigeonhole-unfinished-features"

        system "./configure", *args
        system "make"
        system "make", "install"
      end
    end
  end

  def caveats; <<-EOS.undent
    For Dovecot to work, you may need to create a dovecot user
    and group depending on your configuration file options.
    EOS
  end

  plist_options :startup => true

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>KeepAlive</key>
        <false/>
        <key>RunAtLoad</key>
        <true/>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_sbin}/dovecot</string>
          <string>-F</string>
        </array>
        <key>StandardErrorPath</key>
        <string>#{var}/log/dovecot/dovecot.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/dovecot/dovecot.log</string>
        <key>SoftResourceLimits</key>
        <dict>
        <key>NumberOfFiles</key>
        <integer>1000</integer>
        </dict>
        <key>HardResourceLimits</key>
        <dict>
        <key>NumberOfFiles</key>
        <integer>1024</integer>
        </dict>
      </dict>
    </plist>
    EOS
  end

  test do
    assert_match /#{version}/, shell_output("#{sbin}/dovecot --version")
  end
end
