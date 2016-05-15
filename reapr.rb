class Reapr < Formula
  desc "Evaluates accuracy of a genome assembly using mapped paired end reads"
  homepage "http://www.sanger.ac.uk/science/tools/reapr"
  # doi "10.1186/gb-2013-14-5-r47"
  # tag "bioinformatics"
  url "ftp://ftp.sanger.ac.uk/pub/resources/software/reapr/Reapr_1.0.18.tar.gz"
  sha256 "6d691b5b49c58aef332e771d339e32097a7696e9c68bd8f16808b46d648b6660"

  bottle do
    cellar :any
    sha256 "c2b05bab93220b81d44f8a6b61b4c59f9eba5eed183a4ad0f28fe1f46ff9f14a" => :el_capitan
    sha256 "aa1812958b54fd5974f18f1ed7e084a6441b7111639574995b62762700c009e9" => :yosemite
    sha256 "6d390b5a36e6cc7b56a6fd86b28e443f4dbf073f714bddc866d3781a024a46f6" => :mavericks
  end

  depends_on "bamtools"
  depends_on "htslib"
  depends_on "r" => [:recommended, :run] # only needed for the test
  depends_on "samtools-0.1"
  depends_on "smalt"

  resource "manual" do
    url "ftp://ftp.sanger.ac.uk/pub/resources/software/reapr/Reapr_1.0.18.manual.pdf"
    sha256 "304b7b7b725abc285791d8be3b2aaf6f4afeb38852ce91fa5635dc0a9913a517"
  end

  resource "test_data" do
    url "ftp://ftp.sanger.ac.uk/pub/resources/software/reapr/Reapr_1.0.18.test_data.tar.gz"
    sha256 "6ef426e56c4854cdbb22d7012aca29d22b072de5e63f505be11229df76b12840"
  end

  resource "File::Spec::Link" do
    url "http://search.cpan.org/CPAN/authors/id/R/RM/RMBARKER/File-Copy-Link-0.140.tar.gz"
    sha256 "2063656dcd38bade43dc7f1e2ef5f1b6a8086c2f15d37b334189bd2a28e8ffeb"
  end

  def install
    ENV.prepend_create_path "PERL5LIB", libexec+"lib/perl5"

    resource("File::Spec::Link").stage do
      system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
      system "make"
      system "make", "install"
    end

    if OS.mac?
      inreplace "third_party/snpomatic/src/snpomatic.h",
        "using namespace std ;",
        "using namespace std ;\n#define ulong u_long"
    end

    system "make", "-C", "third_party/tabix"
    system "make", "-C", "third_party/snpomatic"
    system "make", "-C", "src",
      "CFLAGS=-I#{Formula["bamtools"].opt_include}/bamtools"
    doc.install %w[README changelog.txt licence.txt]
    doc.install resource("manual")
    (pkgshare/"test").install resource("test_data")

    cd "src" do
      libexec.install %w[
        bam2fcdEstimate bam2fragCov bam2insert
        bam2perfect fa2gaps fa2gc make_plots n50 scaff2contig
        task_break task_fcdrate task_gapresize task_score task_stats
        task_facheck.pl task_perfectfrombam.pl task_perfectmap.pl
        task_pipeline.pl task_plots.pl task_preprocess.pl task_smaltmap.pl
        task_summary.pl reapr.pl
      ]
    end

    bin.install_symlink libexec+"reapr.pl" => "reapr"
    libexec.install_symlink Formula["htslib"].opt_bin => "tabix"
    libexec.install_symlink Formula["smalt"].opt_bin/"smalt" => "smalt"
    libexec.install_symlink Formula["samtools-0.1"].opt_bin/"samtools" => "samtools"
    libexec.install "third_party/snpomatic/findknownsnps"
    bin.env_script_all_files(libexec, :PERL5LIB => ENV["PERL5LIB"])
    ln_s bin/"reapr", prefix/"reapr"
  end

  test do
    cp_r Dir[pkgshare/"test/*"], testpath
    system "./test.sh"
  end
end
